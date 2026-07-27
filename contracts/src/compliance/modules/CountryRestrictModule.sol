// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {ModuleBase} from "./ModuleBase.sol";
import {IIdentityRegistry} from "../../interfaces/ICompliance.sol";

/// @title CountryRestrictModule
/// @notice Allowlist of ISO-3166 numeric country codes eligible to hold the token.
///         Blocks a transfer to a wallet whose registered country is not allowed —
///         e.g. Reg S offshore gating, or excluding sanctioned jurisdictions.
contract CountryRestrictModule is ModuleBase {
    IIdentityRegistry public immutable identityRegistry;
    // token => country => allowed
    mapping(address => mapping(uint16 => bool)) public allowed;

    event CountrySet(address indexed token, uint16 country, bool allowed);

    constructor(address owner_, IIdentityRegistry registry_) ModuleBase(owner_) {
        identityRegistry = registry_;
    }

    function setCountry(address token, uint16 country, bool allowed_) external onlyOwner {
        allowed[token][country] = allowed_;
        emit CountrySet(token, country, allowed_);
    }

    function setCountries(address token, uint16[] calldata countries, bool allowed_) external onlyOwner {
        for (uint256 i; i < countries.length; ++i) {
            allowed[token][countries[i]] = allowed_;
            emit CountrySet(token, countries[i], allowed_);
        }
    }

    function moduleCheck(address, address to, uint256, address token)
        external
        view
        override
        returns (bool)
    {
        uint16 c = identityRegistry.investorCountry(to);
        return allowed[token][c];
    }
}
