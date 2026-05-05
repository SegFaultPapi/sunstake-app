// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Mock de USDC para tests. Decimales = 6 (igual que USDC real).
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /// @notice Permite a cualquier cuenta mintearse tokens en tests
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
