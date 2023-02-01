// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "popp-interfaces/IPriceOracle.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract PriceOracleMock is
IPriceOracle
{
    uint16 public price;

    constructor(uint16 _price) {
        price = _price;
    }

    function getPrice() external view override returns (uint16) {
        return price;
    }

    function centsToToken(uint256 _usdCents) external view returns (uint256) {
        return (_usdCents * (10 ** 18) /price);
    }
}
