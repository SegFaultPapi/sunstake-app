// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title FractionToken
/// @notice Base abstracta ERC-1155 que gestiona tokens fraccionados de proyectos solares.
///         Cada proyecto usa tokenId = 1 (un contrato por proyecto).
///         Mantiene un registro de inversores para distribución pro-rata de yield.
abstract contract FractionToken is ERC1155, Ownable {
    uint256 public constant TOKEN_ID = 1;

    /// @notice Lista ordenada de inversores con balance > 0
    address[] private _investors;

    /// @notice Indica si una address ya está registrada como inversor
    mapping(address => bool) private _isInvestor;

    /// @notice Total de tokens en circulación
    uint256 private _totalSupply;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) {}

    // -------------------------------------------------------------------------
    // Vista: supply e inversores
    // -------------------------------------------------------------------------

    /// @notice Total de tokens fraccionados emitidos
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Devuelve la lista de todas las wallets con tokens activos
    function getInvestors() public view returns (address[] memory) {
        return _investors;
    }

    /// @notice Número de inversores únicos
    function investorCount() public view returns (uint256) {
        return _investors.length;
    }

    // -------------------------------------------------------------------------
    // Internos: mint y burn
    // -------------------------------------------------------------------------

    /// @notice Emite `amount` tokens al inversor `to` y lo registra si es nuevo
    function _mintTokens(address to, uint256 amount) internal {
        require(to != address(0), "FractionToken: mint a zero address");
        require(amount > 0, "FractionToken: amount must be > 0");

        _mint(to, TOKEN_ID, amount, "");
        _totalSupply += amount;

        if (!_isInvestor[to]) {
            _isInvestor[to] = true;
            _investors.push(to);
        }
    }

    /// @notice Quema los tokens de `from`. Remueve de la lista si queda con balance 0.
    function _burnTokens(address from, uint256 amount) internal {
        require(from != address(0), "FractionToken: burn from zero address");
        uint256 currentBalance = balanceOf(from, TOKEN_ID);
        require(currentBalance >= amount, "FractionToken: burn exceeds balance");

        _burn(from, TOKEN_ID, amount);
        _totalSupply -= amount;

        if (balanceOf(from, TOKEN_ID) == 0) {
            _removeInvestor(from);
        }
    }

    /// @notice Quema todos los tokens de todos los inversores (cierre de proyecto)
    function _burnAllTokens() internal {
        address[] memory investors = _investors;
        for (uint256 i = 0; i < investors.length; i++) {
            uint256 bal = balanceOf(investors[i], TOKEN_ID);
            if (bal > 0) {
                _burn(investors[i], TOKEN_ID, bal);
            }
        }
        _totalSupply = 0;
        // Limpiar el array de inversores
        for (uint256 i = 0; i < investors.length; i++) {
            _isInvestor[investors[i]] = false;
        }
        delete _investors;
    }

    // -------------------------------------------------------------------------
    // Privados
    // -------------------------------------------------------------------------

    function _removeInvestor(address investor) private {
        _isInvestor[investor] = false;
        uint256 len = _investors.length;
        for (uint256 i = 0; i < len; i++) {
            if (_investors[i] == investor) {
                _investors[i] = _investors[len - 1];
                _investors.pop();
                break;
            }
        }
    }
}
