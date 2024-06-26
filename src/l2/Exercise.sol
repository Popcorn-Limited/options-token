pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IOracle} from "../interfaces/IOracle.sol";

/// @dev expects all tokens to use 18 decimals
contract Exercise is Owned {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint;

    /// @notice The token that is exercised
    ERC20 public exerciseToken;

    /// @notice The token paid by the options token holder during redemption
    ERC20 public immutable paymentToken;

    /// @notice The underlying token purchased during redemption
    ERC20 public immutable underlyingToken;

    /// @notice The oracle contract that provides the current price to purchase
    /// the underlying token while exercising options (the strike price)
    IOracle public oracle;

    /// @notice The address that receives the payment token
    address public treasury;

    event Exercised(address indexed sender, address indexed recipient, uint256 amount, uint256 paymentAmount);
    event OracleUpdated(address oldOracle, address newOracle);
    event TreasuryUpdated(address oldTreasury, address newTreasury);

    constructor(
        address _owner,
        ERC20 _exerciseToken,
        ERC20 _paymentToken,
        ERC20 _underlyingToken,
        IOracle _oracle,
        address _treasury
    ) Owned(_owner) {
        exerciseToken = _exerciseToken;
        paymentToken = _paymentToken;
        underlyingToken = _underlyingToken;
        oracle = _oracle;
        treasury = _treasury;

        emit OracleUpdated(address(0), address(_oracle));
        emit TreasuryUpdated(address(0), _treasury);
    }

    /// @notice user has to approve `amount` of `exerciseToken` to the contract before calling
    function exercise(uint amount, uint maxPaymentAmount, address recipient)
        external
        returns (uint paymentAmount)
    {
        require(amount != 0, "can't exercise 0 tokens");

        exerciseToken.safeTransferFrom(msg.sender, address(this), amount);
        
        // get price from oracle.
        // multiply by oVCX amount (check how OptionssToken handles that) to get the
        // amount of VCX we should send to the user and how much WETH we should expect
        paymentAmount = amount.mulWadUp(oracle.getPrice());
        require(paymentAmount <= maxPaymentAmount, "slippage too high");

        paymentToken.safeTransferFrom(msg.sender, treasury, paymentAmount);

        underlyingToken.transfer(recipient, amount);

        emit Exercised(msg.sender, recipient, amount, paymentAmount);
    }
    function setOracle(IOracle newOracle) external onlyOwner {
        emit OracleUpdated(address(oracle), address(newOracle));

        oracle = newOracle;
    }

    function setTreasury(address newTreasury) external onlyOwner {
        emit TreasuryUpdated(treasury, newTreasury);
    
        treasury = newTreasury;
    }
}
