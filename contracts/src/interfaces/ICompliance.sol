// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

/// @notice ERC-3643-aligned interfaces for the LD Capital compliance layer.

interface IIdentityRegistry {
    function isVerified(address wallet) external view returns (bool);
    function investorCountry(address wallet) external view returns (uint16);
    function registerIdentity(address wallet, bytes32 onchainId, uint16 country) external;
    function deleteIdentity(address wallet) external;
}

interface IComplianceModule {
    /// @dev Pure eligibility check for a prospective transfer. MUST NOT mutate state.
    function moduleCheck(address from, address to, uint256 amount, address token)
        external
        view
        returns (bool);

    /// @dev State hooks so modules can track holder counts, lockups, balances.
    function moduleMintAction(address to, uint256 amount, address token) external;
    function moduleBurnAction(address from, uint256 amount, address token) external;
    function moduleTransferAction(address from, address to, uint256 amount, address token) external;
}

interface IModularCompliance {
    function canTransfer(address from, address to, uint256 amount) external view returns (bool);
    function created(address to, uint256 amount) external;
    function destroyed(address from, uint256 amount) external;
    function transferred(address from, address to, uint256 amount) external;
    function token() external view returns (address);
}
