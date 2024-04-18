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

    /**
     * @dev Check if the user has enough collateral to mint DSC
     * @param amountDSC The amount of DSC to mint
     * @notice User must have more collateral value than the minimum threshold
     */
    function mintDSC(uint256 amountDSC) external;

    function burnDSC() external;

    function liquidate() external;

    function getHealthFactor() external view;

    function getAccountCollateralValueInUSD(address user) external view returns (uint256);
}
