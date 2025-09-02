// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IDssFlash {
    function vatDai() external view returns (uint256);
    function max() external view returns (uint256);
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface IERC3156FlashBorrower {
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}