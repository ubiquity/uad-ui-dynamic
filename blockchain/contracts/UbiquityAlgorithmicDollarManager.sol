// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/ICurveFactory.sol";
import "./interfaces/IMetaPool.sol";
import "hardhat/console.sol";

/// @title A central config for the uAD system. Also acts as a central
/// access control manager.
/// @notice For storing constants. For storing variables and allowing them to
/// be changed by the admin (governance)
/// @dev This should be used as a central access control manager which other
/// contracts use to check permissions
contract UbiquityAlgorithmicDollarManager is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant COUPON_MANAGER_ROLE = keccak256("COUPON_MANAGER");
    bytes32 public constant BONDING_MANAGER_ROLE = keccak256("BONDING_MANAGER");

    address public twapOracleAddress;
    address public debtCouponAddress;
    address public uADTokenAddress;
    address public comparisonTokenAddress; // 3Crv
    address public couponCalculatorAddress;
    address public dollarCalculatorAddress;
    address public bondingShareAddress;
    address public stableSwapMetaPoolAddress;

    //key = address of couponmanager, value = excessdollardistributor
    mapping(address => address) private _excessDollarDistributors;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        _;
    }

    constructor(address _admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(COUPON_MANAGER_ROLE, _admin);
        _setupRole(BONDING_MANAGER_ROLE, _admin);
    }

    function setTwapOracleAddress(address _twapOracleAddress)
        external
        onlyAdmin
    {
        twapOracleAddress = _twapOracleAddress;
    }

    function setDebtCouponAddress(address _debtCouponAddress)
        external
        onlyAdmin
    {
        debtCouponAddress = _debtCouponAddress;
    }

    function setuADTokenAddress(address _uADTokenAddress) external onlyAdmin {
        uADTokenAddress = _uADTokenAddress;
    }

    function setComparisonTokenAddress(address _comparisonTokenAddress)
        external
        onlyAdmin
    {
        comparisonTokenAddress = _comparisonTokenAddress;
    }

    function setCouponCalculatorAddress(address _couponCalculatorAddress)
        external
        onlyAdmin
    {
        couponCalculatorAddress = _couponCalculatorAddress;
    }

    function setDollarCalculatorAddress(address _dollarCalculatorAddress)
        external
        onlyAdmin
    {
        dollarCalculatorAddress = _dollarCalculatorAddress;
    }

    function setExcessDollarsDistributor(
        address debtCouponManagerAddress,
        address excessCouponDistributor
    ) external onlyAdmin {
        _excessDollarDistributors[
            debtCouponManagerAddress
        ] = excessCouponDistributor;
    }

    function deployStableSwapPool(
        address _curveFactory,
        address _crvBasePool,
        address _crv3PoolTokenAddress,
        uint256 _amplificationCoefficient,
        uint256 _fee
    ) external onlyAdmin {
        // Create new StableSwap meta pool (uDA <-> 3Crv)
        address metaPool =
            ICurveFactory(_curveFactory).deploy_metapool(
                _crvBasePool,
                ERC20(uADTokenAddress).name(),
                ERC20(uADTokenAddress).symbol(),
                uADTokenAddress,
                _amplificationCoefficient,
                _fee
            );

        stableSwapMetaPoolAddress = metaPool;

        // Approve the newly-deployed meta pool to transfer this contract's funds
        uint256 crv3PoolTokenAmount =
            IERC20(_crv3PoolTokenAddress).balanceOf(address(this));
        uint256 uADTokenAmount =
            IERC20(uADTokenAddress).balanceOf(address(this));

        IERC20(_crv3PoolTokenAddress).safeApprove(metaPool, 0);
        IERC20(_crv3PoolTokenAddress).safeApprove(
            metaPool,
            crv3PoolTokenAmount
        );

        IERC20(uADTokenAddress).safeApprove(metaPool, 0);
        IERC20(uADTokenAddress).safeApprove(metaPool, uADTokenAmount);

        // Add the initial liquidity to the StableSwap meta pool
        uint256[2] memory amounts =
            [
                IERC20(_crv3PoolTokenAddress).balanceOf(address(this)),
                IERC20(uADTokenAddress).balanceOf(address(this))
            ];

        IMetaPool(metaPool).add_liquidity(amounts, 0, msg.sender);
    }

    function setBondingShareAddress(address _bondingShareAddress)
        external
        onlyAdmin
    {
        bondingShareAddress = _bondingShareAddress;
    }

    function setStableSwapMetaPoolAddress(address _stableSwapMetaPoolAddress)
        external
        onlyAdmin
    {
        stableSwapMetaPoolAddress = _stableSwapMetaPoolAddress;
    }

    function getExcessDollarsDistributor(address debtCouponManagerAddress)
        external
        view
        returns (address)
    {
        return _excessDollarDistributors[debtCouponManagerAddress];
    }
}
