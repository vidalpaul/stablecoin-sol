// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
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

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;

    address[] private s_collateralTokens;
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => uint256 amountDSCMinted) private s_DSCMinted;
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
            s_collateralTokens.push(tokenAddresses[i]);
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
    function mintDSC(uint256 amountDSC) external moreThanZero(amountDSC) nonReentrant {
        s_DSCMinted[msg.sender] += amountDSC;
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    // @inheritdoc IDSCEngine
    function burnDSC() external {}

    // @inheritdoc IDSCEngine
    function liquidate() external {}

    // @inheritdoc IDSCEngine
    function getHealthFactor() external view {}

    /**
     * Returns how close to being liquidated the user is
     * If a user goes below 1, then can be liquidated
     * @param user The address of the user to check the health factor for
     */
    function _healthFactor(address user) internal view returns (uint256) {
        (uint256 totalDSCMinted, uint256 totalCollateralValueInUSD) = _totalDSCMintedAndCollateralValueInUSD(user);
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {}

    /**
     *
     * @param user The address of the user to check the health factor for
     * @return totalDSCMinted The total amount of DSC minted by the user
     * @return collaTeralValueInUSD The total value of the user's collateral in USD
     */
    function _totalDSCMintedAndCollateralValueInUSD(address user)
        private
        view
        returns (uint256 totalDSCMinted, uint256 collaTeralValueInUSD)
    {
        totalDSCMinted = s_DSCMinted[user];
        collaTeralValueInUSD = getAccountCollateralValueInUSD(user);
    }

    // @inheritdoc IDSCEngine
    function getAccountCollateralValueInUSD(address user) public view returns (uint256 totalCollateralValueInUSD) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_userCollateralBalances[user][token];
            totalCollateralValueInUSD += getUSDValue(token, amount);
        }
    }

    function getUSDValue(address token, uint256 amount) public view returns (uint256 price) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }
}
