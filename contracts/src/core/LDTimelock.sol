// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

/// @title LDTimelock
/// @notice Minimal timelock to own the core contracts so no privileged topology/policy
///         change fires from a single EOA without a delay. Governance (a multisig) is the
///         admin/proposer; changes queue, wait `delay`, then execute — giving investors and
///         counterparties a window to react. This contract SHOULD be set as `owner` of the
///         registries, compliance, gate, and tokens.
contract LDTimelock {
    uint256 public constant MIN_DELAY = 2 days;
    uint256 public constant MAX_DELAY = 30 days;
    uint256 public constant GRACE_PERIOD = 14 days;

    address public admin;            // governance multisig
    address public pendingAdmin;
    uint256 public delay;

    mapping(bytes32 => bool) public queued;

    event NewAdmin(address indexed admin);
    event NewPendingAdmin(address indexed pendingAdmin);
    event NewDelay(uint256 delay);
    event Queued(bytes32 indexed txHash, address target, uint256 value, bytes data, uint256 eta);
    event Executed(bytes32 indexed txHash, address target, uint256 value, bytes data);
    event Cancelled(bytes32 indexed txHash);

    error NotAdmin();
    error BadDelay();
    error NotQueued();
    error TooEarly();
    error Stale();
    error CallReverted();
    error OnlySelf();

    constructor(address admin_, uint256 delay_) {
        require(admin_ != address(0), "zero admin");
        if (delay_ < MIN_DELAY || delay_ > MAX_DELAY) revert BadDelay();
        admin = admin_;
        delay = delay_;
        emit NewAdmin(admin_);
        emit NewDelay(delay_);
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    /// @dev Delay/admin changes must themselves go through the timelock (call self).
    modifier onlySelf() {
        if (msg.sender != address(this)) revert OnlySelf();
        _;
    }

    function setDelay(uint256 delay_) external onlySelf {
        if (delay_ < MIN_DELAY || delay_ > MAX_DELAY) revert BadDelay();
        delay = delay_;
        emit NewDelay(delay_);
    }

    function setPendingAdmin(address p) external onlySelf {
        pendingAdmin = p;
        emit NewPendingAdmin(p);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "not pending admin");
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit NewAdmin(admin);
    }

    function txHash(address target, uint256 value, bytes calldata data, uint256 eta)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(target, value, data, eta));
    }

    function queue(address target, uint256 value, bytes calldata data, uint256 eta)
        external
        onlyAdmin
        returns (bytes32 h)
    {
        require(eta >= block.timestamp + delay, "eta < now+delay");
        h = txHash(target, value, data, eta);
        queued[h] = true;
        emit Queued(h, target, value, data, eta);
    }

    function cancel(address target, uint256 value, bytes calldata data, uint256 eta)
        external
        onlyAdmin
    {
        bytes32 h = txHash(target, value, data, eta);
        queued[h] = false;
        emit Cancelled(h);
    }

    function execute(address target, uint256 value, bytes calldata data, uint256 eta)
        external
        payable
        onlyAdmin
        returns (bytes memory ret)
    {
        bytes32 h = txHash(target, value, data, eta);
        if (!queued[h]) revert NotQueued();
        if (block.timestamp < eta) revert TooEarly();
        if (block.timestamp > eta + GRACE_PERIOD) revert Stale();
        queued[h] = false;
        bool ok;
        (ok, ret) = target.call{value: value}(data);
        if (!ok) revert CallReverted();
        emit Executed(h, target, value, data);
    }

    receive() external payable {}
}
