// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./IDSCEngine.sol";
import {DSC} from "./DSC.sol";

/**
 * @title DSCEngine
 * @author vidalpaul
 * @notice The DSCEngine contract is the main contract for the DSC protocol.
 * The system is designed to be as minimal as possible, and have the tokens maintain DSC 1:1 USD PEG
 *
 * Our DSC system should always be overcollateralized. At no point, should the value of all collateral <= the $ backed value of all the DSC
 */
contract DSCEngine is IDSCEngine, ReentrancyGuard {
    error DSCEngine__AmountMustBeGreaterThanZero();
    error DSCEngine__TransferFailed();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__TokenNotAllowed();

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256)) private s_userCollateralBalances;

    DSC private immutable i_dsc;

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    modifier isAllowedToken(address _token) {
        if (s_priceFeeds[_token] == address(0)) {
            revert DSCEngine__TokenNotAllowed();
        }
        _;
    }

    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) {
            revert DSCEngine__AmountMustBeGreaterThanZero();
        }
        _;
    }

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }
        i_dsc = DSC(dscAddress);
    }

    // @inheritdoc IDSCEngine
    function depositCollateralAndMintDSC() external {}

    // @inheritdoc IDSCEngine
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_userCollateralBalances[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    // @inheritdoc IDSCEngine
    function redeemCollateralForDSC() external {}

    // @inheritdoc IDSCEngine
    function redeemCollateral() external {}

    // @inheritdoc IDSCEngine
    function mintDSC() external {}

    // @inheritdoc IDSCEngine
    function burnDSC() external {}

    // @inheritdoc IDSCEngine
    function liquidate() external {}

    // @inheritdoc IDSCEngine
    function getHealthFactor() external view {}
}
