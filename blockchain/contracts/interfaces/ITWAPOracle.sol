// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;

interface ITWAPOracle {
    function update() external;

    function consult(uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}
