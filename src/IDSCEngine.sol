// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

interface IDSCEngine {
    function depositCollateralAndMintDSC() external;

    /**
     * @notice Follows CEI pattern
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of the token to deposit as collateral
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) external;

    function redeemCollateralForDSC() external;

    function redeemCollateral() external;

    function mintDSC() external;

    function burnDSC() external;

    function liquidate() external;

    function getHealthFactor() external view;
}
