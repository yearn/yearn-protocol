pragma solidity ^0.5.17;

/**
@title ILendingPoolAddressesProvider interface
@notice provides the interface to fetch the LendingPoolCore address
 */

contract ILendingPoolAddressesProvider {
    /**
     * @dev returns the address of the LendingPool proxy
     * @return the lending pool proxy address
     **/
    function getLendingPool() external view returns (address);

    /**
     * @dev updates the implementation of the lending pool
     * @param _pool the new lending pool implementation
     **/
    function setLendingPoolImpl(address _pool) external;

    /**
     * @dev returns the address of the LendingPoolCore proxy
     * @return the lending pool core proxy address
     */
    function getLendingPoolCore() external view returns (address payable);

    /**
     * @dev updates the implementation of the lending pool core
     * @param _lendingPoolCore the new lending pool core implementation
     **/
    function setLendingPoolCoreImpl(address _lendingPoolCore) external;

    /**
     * @dev returns the address of the LendingPoolConfigurator proxy
     * @return the lending pool configurator proxy address
     **/
    function getLendingPoolConfigurator() external view returns (address);

    /**
     * @dev updates the implementation of the lending pool configurator
     * @param _configurator the new lending pool configurator implementation
     **/
    function setLendingPoolConfiguratorImpl(address _configurator) external;

    /**
     * @dev returns the address of the LendingPoolDataProvider proxy
     * @return the lending pool data provider proxy address
     */
    function getLendingPoolDataProvider() external view returns (address);

    /**
     * @dev updates the implementation of the lending pool data provider
     * @param _provider the new lending pool data provider implementation
     **/
    function setLendingPoolDataProviderImpl(address _provider) external;

    /**
     * @dev returns the address of the LendingPoolParametersProvider proxy
     * @return the address of the Lending pool parameters provider proxy
     **/
    function getLendingPoolParametersProvider() external view returns (address);

    /**
     * @dev updates the implementation of the lending pool parameters provider
     * @param _parametersProvider the new lending pool parameters provider implementation
     **/
    function setLendingPoolParametersProviderImpl(address _parametersProvider) external;

    function getTokenDistributor() external view returns (address);

    function setTokenDistributor(address _tokenDistributor) external;

    /**
     * @dev returns the address of the FeeProvider proxy
     * @return the address of the Fee provider proxy
     **/
    function getFeeProvider() external view returns (address);

    /**
     * @dev updates the implementation of the FeeProvider proxy
     * @param _feeProvider the new lending pool fee provider implementation
     **/
    function setFeeProviderImpl(address _feeProvider) external;

    /**
     * @dev returns the address of the LendingPoolLiquidationManager. Since the manager is used
     * through delegateCall within the LendingPool contract, the proxy contract pattern does not work properly hence
     * the addresses are changed directly.
     * @return the address of the Lending pool liquidation manager
     **/
    function getLendingPoolLiquidationManager() external view returns (address);

    /**
     * @dev updates the address of the Lending pool liquidation manager
     * @param _manager the new lending pool liquidation manager address
     **/
    function setLendingPoolLiquidationManager(address _manager) external;

    function getLendingPoolManager() external view returns (address);

    function setLendingPoolManager(address _lendingPoolManager) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address _priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address _lendingRateOracle) external;
}
