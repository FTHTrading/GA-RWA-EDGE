// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "../core/Roles.sol";
import {IIdentityRegistry, IModularCompliance} from "../interfaces/ICompliance.sol";
import {AMLTravelRuleGate} from "../core/AMLTravelRuleGate.sol";

/// @title LDSecurityToken
/// @notice ERC-3643-style permissioned security token — the LD Capital regulated-asset
///         instrument. Every transfer is a hard gate: it reverts unless both parties are
///         verified identities, neither is frozen, the token is not paused, there is no
///         frozen-token shortfall, and every compliance module approves.
/// @dev    Integer base units only. Agent-gated mint/burn/freeze/forcedTransfer;
///         owner-gated registry/compliance topology. Non-custodial: issuer can freeze and
///         recover (audited) but never silently moves investor funds.
contract LDSecurityToken is Roles {
    string public name;
    string public symbol;
    uint8 public immutable decimals;

    uint256 public totalSupply;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowance;

    // compliance / identity
    IIdentityRegistry public identityRegistry;
    IModularCompliance public compliance;
    AMLTravelRuleGate public amlGate; // optional in code, mandatory by deploy policy

    // freeze + pause state
    bool public paused;
    mapping(address => bool) public frozen;            // whole-wallet freeze
    mapping(address => uint256) public frozenTokens;   // partial freeze amount

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event Paused(bool paused);
    event AddressFrozen(address indexed wallet, bool frozen);
    event TokensFrozen(address indexed wallet, uint256 amount);
    event TokensUnfrozen(address indexed wallet, uint256 amount);
    event ForcedTransfer(address indexed from, address indexed to, uint256 amount);
    event RecoverySuccess(address indexed lost, address indexed replacement, bytes32 onchainId);
    event RegistrySet(address identityRegistry, address compliance);
    event AmlGateSet(address amlGate);

    error TokenPaused();
    error WalletFrozen();
    error NotVerified();
    error ComplianceFail();
    error FrozenShortfall();
    error InsufficientBalance();
    error InsufficientAllowance();
    error AmlBlocked(string code);

    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        IIdentityRegistry identityRegistry_,
        IModularCompliance compliance_
    ) Roles(owner_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        identityRegistry = identityRegistry_;
        compliance = compliance_;
        emit RegistrySet(address(identityRegistry_), address(compliance_));
    }

    // ---- views ----
    function balanceOf(address a) public view returns (uint256) {
        return _balance[a];
    }

    function allowance(address o, address s) external view returns (uint256) {
        return _allowance[o][s];
    }

    /// @notice Spendable = balance minus partially frozen tokens.
    function unfrozenBalance(address a) public view returns (uint256) {
        return _balance[a] - frozenTokens[a];
    }

    /// @notice Full ERC-3643 eligibility preview without mutating state.
    function canTransfer(address from, address to, uint256 amount) public view returns (bool) {
        if (paused) return false;
        if (frozen[from] || frozen[to]) return false;
        if (unfrozenBalance(from) < amount) return false;
        if (!identityRegistry.isVerified(to)) return false;
        return compliance.canTransfer(from, to, amount);
    }

    // ---- ERC-20 with the gate ----
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _gatedTransfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 a = _allowance[from][msg.sender];
        if (a < amount) revert InsufficientAllowance();
        if (a != type(uint256).max) _allowance[from][msg.sender] = a - amount;
        _gatedTransfer(from, to, amount);
        return true;
    }

    function _gatedTransfer(address from, address to, uint256 amount) internal {
        if (paused) revert TokenPaused();
        if (frozen[from] || frozen[to]) revert WalletFrozen();
        if (unfrozenBalance(from) < amount) revert FrozenShortfall();
        if (!identityRegistry.isVerified(to)) revert NotVerified();
        if (!compliance.canTransfer(from, to, amount)) revert ComplianceFail();
        _aml(from, to, amount);

        _balance[from] -= amount;
        _balance[to] += amount;
        compliance.transferred(from, to, amount);
        emit Transfer(from, to, amount);
    }

    /// @dev AML/Travel-Rule gate — the last precondition before value moves. Optional in
    ///      code (skipped when unset) but mandatory per deploy policy; the gate itself is
    ///      fail-closed. P2P transfers carry no travel-rule ref (bytes32(0)); the gate
    ///      routes over-threshold refless transfers to REVIEW → revert.
    function _aml(address from, address to, uint256 amount) internal {
        AMLTravelRuleGate g = amlGate;
        if (address(g) == address(0)) return;
        (AMLTravelRuleGate.Decision d, string memory code) = g.evaluate(from, to, amount, bytes32(0));
        if (d != AMLTravelRuleGate.Decision.ALLOW) revert AmlBlocked(code);
    }

    function setAmlGate(AMLTravelRuleGate g) external onlyOwner {
        amlGate = g;
        emit AmlGateSet(address(g));
    }

    // ---- agent operations ----
    function mint(address to, uint256 amount) external onlyAgent {
        if (!identityRegistry.isVerified(to)) revert NotVerified();
        if (!compliance.canTransfer(address(0), to, amount)) revert ComplianceFail();
        _aml(address(0), to, amount);
        _balance[to] += amount;
        totalSupply += amount;
        compliance.created(to, amount);
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external onlyAgent {
        if (_balance[from] < amount) revert InsufficientBalance();
        // Unfreeze first if burning into frozen tokens.
        uint256 fz = frozenTokens[from];
        if (_balance[from] - fz < amount && fz > 0) {
            uint256 need = amount - (_balance[from] - fz);
            frozenTokens[from] = fz - need;
            emit TokensUnfrozen(from, need);
        }
        _balance[from] -= amount;
        totalSupply -= amount;
        compliance.destroyed(from, amount);
        emit Burn(from, amount);
        emit Transfer(from, address(0), amount);
    }

    function setPaused(bool p) external onlyAgent {
        paused = p;
        emit Paused(p);
    }

    function setAddressFrozen(address wallet, bool f) external onlyAgent {
        frozen[wallet] = f;
        emit AddressFrozen(wallet, f);
    }

    function freezePartialTokens(address wallet, uint256 amount) public onlyAgent {
        if (_balance[wallet] < frozenTokens[wallet] + amount) revert InsufficientBalance();
        frozenTokens[wallet] += amount;
        emit TokensFrozen(wallet, amount);
    }

    function unfreezePartialTokens(address wallet, uint256 amount) external onlyAgent {
        if (frozenTokens[wallet] < amount) revert InsufficientBalance();
        frozenTokens[wallet] -= amount;
        emit TokensUnfrozen(wallet, amount);
    }

    /// @notice Governance recovery path. Bypasses freeze but NOT the recipient identity
    ///         check. The ONLY sanctioned way to move a third party's tokens — auditable.
    function forcedTransfer(address from, address to, uint256 amount) public onlyAgent {
        if (!identityRegistry.isVerified(to)) revert NotVerified();
        // Recovery/court-order path deliberately bypasses monitoring, but a SANCTIONED
        // recipient is a hard stop even here.
        if (address(amlGate) != address(0) && amlGate.sanctioned(to)) revert AmlBlocked("OFAC_SDN_MATCH");
        if (_balance[from] < amount) revert InsufficientBalance();
        // Release frozen tokens up to the forced amount if needed.
        uint256 free = unfrozenBalance(from);
        if (free < amount) {
            uint256 unf = amount - free;
            frozenTokens[from] -= unf;
            emit TokensUnfrozen(from, unf);
        }
        _balance[from] -= amount;
        _balance[to] += amount;
        compliance.transferred(from, to, amount);
        emit ForcedTransfer(from, to, amount);
        emit Transfer(from, to, amount);
    }

    /// @notice Move an entire balance from a lost wallet to a replacement bound to the
    ///         same investor identity. Off-chain legal verification precedes this call.
    function recoveryAddress(address lostWallet, address newWallet, bytes32 investorOnchainId)
        external
        onlyAgent
        returns (bool)
    {
        uint256 bal = _balance[lostWallet];
        if (bal == 0) revert InsufficientBalance();
        uint16 country = identityRegistry.investorCountry(lostWallet);
        identityRegistry.registerIdentity(newWallet, investorOnchainId, country);

        uint256 fz = frozenTokens[lostWallet];
        forcedTransfer(lostWallet, newWallet, bal);
        if (fz > 0) freezePartialTokens(newWallet, fz);
        if (frozen[lostWallet]) {
            frozen[newWallet] = true;
            emit AddressFrozen(newWallet, true);
        }
        identityRegistry.deleteIdentity(lostWallet);
        emit RecoverySuccess(lostWallet, newWallet, investorOnchainId);
        return true;
    }

    // ---- owner topology ----
    function setRegistries(IIdentityRegistry ir, IModularCompliance c) external onlyOwner {
        identityRegistry = ir;
        compliance = c;
        emit RegistrySet(address(ir), address(c));
    }
}
