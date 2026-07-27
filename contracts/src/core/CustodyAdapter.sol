// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "./Roles.sol";

/// @title CustodyAdapter
/// @notice The custody boundary for privileged agent operations. Holds the AGENT role on
///         core contracts (token mint/burn/freeze/forcedTransfer, waterfall writedown,
///         sweeps) and makes every such op pass 4-eyes (m-of-n distinct approvers) plus a
///         per-window velocity limit and an optional execution delay before it fires.
/// @dev    Mirrors the BitGo posture on-chain: no single key/EOA can move value; the
///         proposer must differ from approvers; funds are never held here. Amounts are
///         integer minor units. Idempotent execution via one-shot proposal state.
contract CustodyAdapter is Roles {
    struct Proposal {
        address target;
        bytes   data;
        uint256 declaredValue; // for velocity accounting (minor units)
        address proposer;
        uint64  createdAt;
        uint32  approvals;
        bool    executed;
    }

    mapping(address => bool) public isApprover;
    uint256 public approverCount;
    uint256 public threshold;         // m distinct approvers required
    uint256 public execDelay;         // seconds after reaching quorum before execute
    uint256 public velocityWindow;    // seconds
    uint256 public velocityMax;       // max declaredValue per window

    mapping(bytes32 => Proposal) public proposals;
    mapping(bytes32 => mapping(address => bool)) public approved;
    uint256 public nonce;

    struct Window { uint64 start; uint256 sum; }
    Window private _vel;

    event ApproverSet(address indexed approver, bool enabled);
    event ThresholdSet(uint256 threshold);
    event ParamsSet(uint256 execDelay, uint256 velocityWindow, uint256 velocityMax);
    event Proposed(bytes32 indexed id, address indexed proposer, address target, uint256 declaredValue);
    event Approved(bytes32 indexed id, address indexed approver, uint32 approvals);
    event Executed(bytes32 indexed id, address target, bool success);

    error NotApprover();
    error AlreadyApprover();
    error BadThreshold();
    error ProposerCannotApprove();
    error AlreadyApproved();
    error UnknownProposal();
    error AlreadyExecuted();
    error QuorumNotReached();
    error DelayNotElapsed();
    error VelocityExceeded();
    error CallReverted();

    constructor(
        address owner_,
        address[] memory approvers_,
        uint256 threshold_,
        uint256 execDelay_,
        uint256 velocityWindow_,
        uint256 velocityMax_
    ) Roles(owner_) {
        for (uint256 i; i < approvers_.length; ++i) {
            if (approvers_[i] == address(0)) revert ZeroAddress();
            if (!isApprover[approvers_[i]]) {
                isApprover[approvers_[i]] = true;
                approverCount += 1;
                emit ApproverSet(approvers_[i], true);
            }
        }
        if (threshold_ == 0 || threshold_ > approverCount) revert BadThreshold();
        threshold = threshold_;
        execDelay = execDelay_;
        velocityWindow = velocityWindow_;
        velocityMax = velocityMax_;
        emit ThresholdSet(threshold_);
        emit ParamsSet(execDelay_, velocityWindow_, velocityMax_);
    }

    // ---- admin (owner = timelock/governance) ----
    function setApprover(address a, bool enabled) external onlyOwner {
        if (a == address(0)) revert ZeroAddress();
        if (enabled && !isApprover[a]) { isApprover[a] = true; approverCount += 1; }
        else if (!enabled && isApprover[a]) { isApprover[a] = false; approverCount -= 1; }
        else revert AlreadyApprover();
        emit ApproverSet(a, enabled);
    }

    function setThreshold(uint256 m) external onlyOwner {
        if (m == 0 || m > approverCount) revert BadThreshold();
        threshold = m;
        emit ThresholdSet(m);
    }

    function setParams(uint256 execDelay_, uint256 velWindow_, uint256 velMax_) external onlyOwner {
        execDelay = execDelay_;
        velocityWindow = velWindow_;
        velocityMax = velMax_;
        emit ParamsSet(execDelay_, velWindow_, velMax_);
    }

    // ---- 4-eyes flow ----
    /// @notice Propose a privileged call. The proposer must be an approver but their
    ///         proposal does NOT count as an approval (proposer != approver rule).
    function propose(address target, bytes calldata data, uint256 declaredValue)
        external
        returns (bytes32 id)
    {
        if (!isApprover[msg.sender]) revert NotApprover();
        id = keccak256(abi.encode(target, data, declaredValue, nonce++));
        proposals[id] = Proposal({
            target: target,
            data: data,
            declaredValue: declaredValue,
            proposer: msg.sender,
            createdAt: uint64(block.timestamp),
            approvals: 0,
            executed: false
        });
        emit Proposed(id, msg.sender, target, declaredValue);
    }

    function approve(bytes32 id) external {
        if (!isApprover[msg.sender]) revert NotApprover();
        Proposal storage p = proposals[id];
        if (p.target == address(0)) revert UnknownProposal();
        if (p.executed) revert AlreadyExecuted();
        if (msg.sender == p.proposer) revert ProposerCannotApprove();
        if (approved[id][msg.sender]) revert AlreadyApproved();
        approved[id][msg.sender] = true;
        p.approvals += 1;
        emit Approved(id, msg.sender, p.approvals);
    }

    function quorumReachedAt(bytes32 id) public view returns (bool) {
        return proposals[id].approvals >= threshold;
    }

    /// @notice Execute once quorum + delay + velocity clear. One-shot (idempotent).
    function execute(bytes32 id) external returns (bool success) {
        Proposal storage p = proposals[id];
        if (p.target == address(0)) revert UnknownProposal();
        if (p.executed) revert AlreadyExecuted();
        if (p.approvals < threshold) revert QuorumNotReached();
        if (block.timestamp < p.createdAt + execDelay) revert DelayNotElapsed();

        // velocity check on declared value
        if (velocityMax != 0 && p.declaredValue != 0) {
            uint256 projected =
                (block.timestamp - _vel.start > velocityWindow) ? p.declaredValue : _vel.sum + p.declaredValue;
            if (projected > velocityMax) revert VelocityExceeded();
            if (block.timestamp - _vel.start > velocityWindow) {
                _vel.start = uint64(block.timestamp);
                _vel.sum = p.declaredValue;
            } else {
                _vel.sum += p.declaredValue;
            }
        }

        p.executed = true; // set before external call (reentrancy: no re-exec)
        (success, ) = p.target.call(p.data);
        if (!success) revert CallReverted();
        emit Executed(id, p.target, success);
    }
}
