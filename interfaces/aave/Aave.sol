pragma solidity ^0.5.17;

interface Aave {
    function getRevision() internal pure returns (uint256);

    /**
     * @dev deposits The underlying asset into the reserve. A corresponding amount of the overlying asset (aTokens)
     * is minted.
     * @param _reserve the address of the reserve
     * @param _amount the amount to be deposited
     * @param _referralCode integrators are assigned a referral code and can potentially receive rewards.
     **/
    function deposit(
        address _reserve,
        uint256 _amount,
        uint16 _referralCode
    ) external payable;

    /**
     * @dev Redeems the underlying amount of assets requested by _user.
     * This function is executed by the overlying aToken contract in response to a redeem action.
     * @param _reserve the address of the reserve
     * @param _user the address of the user performing the action
     * @param _amount the underlying amount to be redeemed
     **/
    function redeemUnderlying(
        address _reserve,
        address payable _user,
        uint256 _amount,
        uint256 _aTokenBalanceAfterRedeem
    ) external;

    /**
     * @dev borrowers can user this function to swap between stable and variable borrow rate modes.
     * @param _reserve the address of the reserve on which the user borrowed
     **/
    function swapBorrowRateMode(address _reserve) external;

    /**
     * @dev rebalances the stable interest rate of a user if current liquidity rate > user stable rate.
     * this is regulated by Aave to ensure that the protocol is not abused, and the user is paying a fair
     * rate. Anyone can call this function though.
     * @param _reserve the address of the reserve
     * @param _user the address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address _reserve, address _user) external;

    /**
     * @dev users can invoke this function to liquidate an undercollateralized position.
     * @param _reserve the address of the collateral to liquidated
     * @param _reserve the address of the principal reserve
     * @param _user the address of the borrower
     * @param _purchaseAmount the amount of principal that the liquidator wants to repay
     * @param _receiveAToken true if the liquidators wants to receive the aTokens, false if
     * he wants to receive the underlying asset directly
     **/
    function liquidationCall(
        address _collateral,
        address _reserve,
        address _user,
        uint256 _purchaseAmount,
        bool _receiveAToken
    ) external payable;

    function getReserveConfigurationData(address _reserve)
        external
        view
        returns (
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            address interestRateStrategyAddress,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive
        );

    function getReserveData(address _reserve)
        external
        view
        returns (
            uint256 totalLiquidity,
            uint256 availableLiquidity,
            uint256 totalBorrowsStable,
            uint256 totalBorrowsVariable,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 utilizationRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            address aTokenAddress,
            uint40 lastUpdateTimestamp
        );

    function getReserves() external view returns (address[] memory);

    function borrow(
        address _reserve,
        uint256 _amount,
        uint256 _interestRateModel,
        uint16 _referralCode
    ) external;

    function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external;

    function repay(
        address _reserve,
        uint256 _amount,
        address payable _onBehalfOf
    ) external payable;

    function getUserAccountData(address _user)
        external
        view
        returns (
            uint256 totalLiquidityETH,
            uint256 totalCollateralETH,
            uint256 totalBorrowsETH,
            uint256 totalFeesETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getUserReserveData(address _reserve, address _user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentBorrowBalance,
            uint256 principalBorrowBalance,
            uint256 borrowRateMode,
            uint256 borrowRate,
            uint256 liquidityRate,
            uint256 originationFee,
            uint256 variableBorrowIndex,
            uint256 lastUpdateTimestamp,
            bool usageAsCollateralEnabled
        );
}
