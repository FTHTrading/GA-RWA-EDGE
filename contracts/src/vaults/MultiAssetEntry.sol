// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "../core/Roles.sol";
import {IERC20} from "../interfaces/IERC20.sol";

/// @title MultiAssetEntry (ERC-7575-style skeleton)
/// @notice One common Share Token, many entry-point vault contracts. Each entry accepts a different
///         deposit asset (USDC, BUIDL, OUSG, tokenized NoteToken, etc.) and mints the SAME shared
///         Share Token to the depositor. Compliance / ERC-3643 rules live on the Share Token, not
///         on the individual entry vaults — one gate regardless of deposit asset.
/// @dev    This is the ORCHESTRATOR / lookup layer. It records the reverse mapping `asset => entryVault`
///         so integrators can discover which entry to hit for a given deposit asset. Actual per-asset
///         deposit / mint mechanics live in each entry vault (typically an AsyncVault instance).
///         Entry vaults are NOT themselves ERC-20 tokens under ERC-7575.
///         Production version must additionally:
///           - Implement ERC-165 interface support
///           - Expose `share()` returning the address of the common Share Token
///           - Expose `vault(asset)` for the reverse lookup
///           - Enforce decimal normalization on Share Token amounts (typically 18 decimals)
///           - Cap the entry-vault set to 2-4 assets for gas economics
contract MultiAssetEntry is Roles {
    address public immutable shareToken;
    mapping(address => address) private _vaultByAsset;
    address[] public registeredAssets;

    event EntryVaultRegistered(address indexed asset, address indexed vault);
    event EntryVaultRemoved(address indexed asset, address indexed vault);

    error AssetAlreadyRegistered();
    error AssetNotRegistered();
    error ShareMismatch();

    constructor(address owner_, address shareToken_) Roles(owner_) {
        if (shareToken_ == address(0)) revert ZeroAddress();
        shareToken = shareToken_;
    }

    /// @notice Register an entry-point vault for a deposit asset.
    /// @dev    Caller (owner) must have verified that the entryVault's `share()` returns this contract's
    ///         Share Token. Off-chain audit responsibility until the ERC-7575 view functions are added
    ///         to the entry-vault interface in the production version.
    function registerEntryVault(address asset, address entryVault) external onlyOwner {
        if (asset == address(0) || entryVault == address(0)) revert ZeroAddress();
        if (_vaultByAsset[asset] != address(0)) revert AssetAlreadyRegistered();
        _vaultByAsset[asset] = entryVault;
        registeredAssets.push(asset);
        emit EntryVaultRegistered(asset, entryVault);
    }

    /// @notice Remove an entry-point vault.
    function removeEntryVault(address asset) external onlyOwner {
        address entryVault = _vaultByAsset[asset];
        if (entryVault == address(0)) revert AssetNotRegistered();
        delete _vaultByAsset[asset];
        // Remove from registeredAssets array (swap-and-pop)
        uint256 len = registeredAssets.length;
        for (uint256 i = 0; i < len; i++) {
            if (registeredAssets[i] == asset) {
                registeredAssets[i] = registeredAssets[len - 1];
                registeredAssets.pop();
                break;
            }
        }
        emit EntryVaultRemoved(asset, entryVault);
    }

    /// @notice Reverse lookup — which entry vault accepts `asset`?
    function vault(address asset) external view returns (address) {
        return _vaultByAsset[asset];
    }

    function assetCount() external view returns (uint256) {
        return registeredAssets.length;
    }
}
