pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

import {PushOracle} from "../../src/l2/PushOracle.sol";
import {Exercise} from "../../src/l2/Exercise.sol";
import {IOracle} from "../../src/interfaces/IOracle.sol";

contract ExerciseTest is Test {
    using FixedPointMathLib for uint256;

    uint constant MAX_SUPPLY = 1e27; // the max supply of the options token & the underlying token

    address owner = makeAddr("owner");
    address treasury = makeAddr("treasury");

    MockERC20 exerciseToken;
    MockERC20 underlyingToken;
    MockERC20 paymentToken;
    PushOracle oracle;
    Exercise exercise;

    function setUp() public {
        exerciseToken = new MockERC20("Exercise Token", "E", 18);
        vm.label(address(exerciseToken), "ExerciseToken");
        underlyingToken = new MockERC20("Underlying Token", "U", 18);
        vm.label(address(underlyingToken), "UnderlyingToken");
        paymentToken = new MockERC20("Payment Token", "P", 18);
        vm.label(address(paymentToken), "PaymentToken");
        oracle = new PushOracle(owner);
        vm.label(address(oracle), "Oracle");
        exercise = new Exercise(
            owner,
            ERC20(address(exerciseToken)),
            ERC20(address(paymentToken)),
            ERC20(address(underlyingToken)),
            IOracle(address(oracle)),
            treasury
        );
        vm.label(address(exercise), "Exercise");

        underlyingToken.mint(address(exercise), type(uint).max);
        paymentToken.approve(address(exercise), type(uint).max);
        exerciseToken.approve(address(exercise), type(uint).max);
    
        // 1 underlying token costs 0.5 payment tokens
        vm.prank(owner);
        oracle.setPrice(5e17);
    }

    function test_exerciseHappyPath(uint amount, address recipient) public {
        amount = bound(amount, 1e6, MAX_SUPPLY);
        exerciseToken.mint(address(this), amount);
        uint expectedPaymentAmount = amount.mulWadUp(5e17);
        paymentToken.mint(address(this), expectedPaymentAmount);
        uint paymentAmount = exercise.exercise(amount, type(uint).max, recipient);

        assertEq(paymentToken.balanceOf(address(this)), 0, "user still holds payment tokens");
        assertEq(expectedPaymentAmount, paymentAmount, "payment amount doesn't match");
        assertEq(paymentToken.balanceOf(treasury), paymentAmount, "treasury didn't receive payment token");
        assertEq(exerciseToken.balanceOf(address(this)), 0, "user still holds exercise tokens");
        assertEq(exerciseToken.balanceOf(address(0)), amount, "exercise token wasn't transferred to 0 address");
        assertEq(underlyingToken.balanceOf(recipient), amount, "recipient didn't get underlying token");
    }

    function test_ownerCanUpdateOracle() public {
        address newOracle = makeAddr("oracle2");

        vm.prank(owner);
        exercise.setOracle(IOracle(newOracle));

        assertEq(address(exercise.oracle()), newOracle, "oracle wasn't updated");
    }

    function test_onlyOwnerCanUpdateOracle() public {
        address newOracle = makeAddr("oracle2");

        vm.expectRevert("UNAUTHORIZED");
        exercise.setOracle(IOracle(newOracle));
    }

    function test_ownerCanUpdateTreasury() public {
        address newTreasury = makeAddr("treasury2");

        vm.prank(owner);
        exercise.setTreasury(newTreasury);

        assertEq(address(exercise.treasury()), newTreasury, "oracle wasn't updated");
    }

    function test_onlyOwnerCanUpdateTreasury() public {
        address newTreasury = makeAddr("treasuryw");

        vm.expectRevert("UNAUTHORIZED");
        exercise.setTreasury(newTreasury);
    }
}