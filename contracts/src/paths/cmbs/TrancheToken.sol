// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "../../core/Roles.sol";
import {ReentrancyGuard} from "../../core/ReentrancyGuard.sol";
import {IIdentityRegistry} from "../../interfaces/ICompliance.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {AMLTravelRuleGate} from "../../core/AMLTravelRuleGate.sol";

/// @title TrancheToken
/// @notice Compliance-gated CMBS tranche ownership token with a dust-free magnified
///         dividend distributor. The Waterfall pushes USDC allocations here via
///         `allocate`; holders `claim` their pro-rata share — but ONLY if their wallet is
///         a verified identity. Ineligible holders accrue and cannot pull until cured.
/// @dev    Magnified accumulator pattern (scaled by 2**128) makes per-share division
///         dust-free. Integer USDC minor units (6dp) throughout. Distribution asset is
///         set once (USDC). Transfers are agent-gated (institutional tranche holders),
///         and always keep dividend corrections consistent.
contract TrancheToken is Roles, ReentrancyGuard {
    string public name;
    string public symbol;
    uint8 public constant decimals = 0; // tranche units are whole ownership shares

    IIdentityRegistry public identityRegistry;
    IERC20 public immutable payoutAsset; // USDC
    address public distributor;          // the Waterfall
    AMLTravelRuleGate public amlGate;    // optional; gates the USDC payout on claim

    uint256 public totalSupply;
    mapping(address => uint256) private _balance;

    uint256 internal constant MAGNITUDE = 2 ** 128;
    uint256 public magnifiedDividendPerShare;
    mapping(address => int256) internal magnifiedCorrections;
    mapping(address => uint256) public withdrawnDividends;
    uint256 public totalDividendsDistributed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event DividendsAllocated(uint256 amount, uint256 perShare);
    event DividendClaimed(address indexed holder, uint256 amount);
    event DistributorSet(address indexed distributor);
    event AmlGateSet(address amlGate);

    error NotDistributor();
    error AmlBlocked(string code);
    error NotVerified();
    error NoSupply();
    error NothingToClaim();
    error PayoutTransferFailed();

    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        IIdentityRegistry identityRegistry_,
        IERC20 payoutAsset_
    ) Roles(owner_) {
        name = name_;
        symbol = symbol_;
        identityRegistry = identityRegistry_;
        payoutAsset = payoutAsset_;
    }

    function setDistributor(address d) external onlyOwner {
        distributor = d;
        emit DistributorSet(d);
    }

    function setAmlGate(AMLTravelRuleGate g) external onlyOwner {
        amlGate = g;
        emit AmlGateSet(address(g));
    }

    function balanceOf(address a) external view returns (uint256) {
        return _balance[a];
    }

    // ---- ownership issuance (agent-gated primary allocation of tranche units) ----
    function issue(address to, uint256 units) external onlyAgent {
        if (!identityRegistry.isVerified(to)) revert NotVerified();
        _balance[to] += units;
        totalSupply += units;
        magnifiedCorrections[to] -= int256(magnifiedDividendPerShare * units);
        emit Transfer(address(0), to, units);
    }

    /// @notice Agent-gated secondary transfer of tranche units (recipient must be verified).
    function transferUnits(address from, address to, uint256 units) external onlyAgent {
        if (!identityRegistry.isVerified(to)) revert NotVerified();
        _balance[from] -= units;
        _balance[to] += units;
        int256 delta = int256(magnifiedDividendPerShare * units);
        magnifiedCorrections[from] += delta;
        magnifiedCorrections[to] -= delta;
        emit Transfer(from, to, units);
    }

    // ---- distribution ----
    /// @notice Called by the Waterfall AFTER it has transferred `amount` USDC to this
    ///         contract. Increases the per-share accumulator dust-free.
    function allocate(uint256 amount) external {
        if (msg.sender != distributor) revert NotDistributor();
        if (totalSupply == 0) revert NoSupply();
        if (amount == 0) return;
        magnifiedDividendPerShare += (amount * MAGNITUDE) / totalSupply;
        totalDividendsDistributed += amount;
        emit DividendsAllocated(amount, magnifiedDividendPerShare);
    }

    function accumulativeDividendOf(address holder) public view returns (uint256) {
        int256 acc = int256(magnifiedDividendPerShare * _balance[holder]) + magnifiedCorrections[holder];
        return uint256(acc) / MAGNITUDE;
    }

    function withdrawableDividendOf(address holder) public view returns (uint256) {
        return accumulativeDividendOf(holder) - withdrawnDividends[holder];
    }

    /// @notice Pull the caller's accrued USDC. Reverts if the caller is not (still) a
    ///         verified identity — compliance gate applies even at claim time.
    function claim() external nonReentrant returns (uint256 amount) {
        if (!identityRegistry.isVerified(msg.sender)) revert NotVerified();
        amount = withdrawableDividendOf(msg.sender);
        if (amount == 0) revert NothingToClaim();
        // Effect BEFORE any external call (checks-effects-interactions): mark withdrawn
        // first so a reentrant/read-only-reentrant path cannot double-compute the claim.
        withdrawnDividends[msg.sender] += amount;
        // AML/Travel-Rule gate on the outbound USDC payout (fail-closed; optional in code).
        AMLTravelRuleGate g = amlGate;
        if (address(g) != address(0)) {
            (AMLTravelRuleGate.Decision d, string memory code) =
                g.evaluate(address(this), msg.sender, amount, bytes32(0));
            if (d != AMLTravelRuleGate.Decision.ALLOW) revert AmlBlocked(code);
        }
        if (!payoutAsset.transfer(msg.sender, amount)) revert PayoutTransferFailed();
        emit DividendClaimed(msg.sender, amount);
    }
}
