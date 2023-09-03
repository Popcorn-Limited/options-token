// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {OptionsToken} from "../src/OptionsToken.sol";
import {TestERC20Mintable} from "./mocks/TestERC20Mintable.sol";
import {BalancerOracle} from "../src/oracles/BalancerOracle.sol";
import {IBalancerTwapOracle} from "../src/interfaces/IBalancerTwapOracle.sol";
import {MockBalancerTwapOracle} from "./mocks/MockBalancerTwapOracle.sol";

contract OptionsTokenTest is Test {
    using FixedPointMathLib for uint256;

    uint16 constant ORACLE_MULTIPLIER = 5000; // 0.5
    uint56 constant ORACLE_SECS = 30 minutes;
    uint56 constant ORACLE_AGO = 2 minutes;
    uint128 constant ORACLE_MIN_PRICE = 1e17;
    uint56 constant ORACLE_LARGEST_SAFETY_WINDOW = 24 hours;
    uint256 constant ORACLE_INIT_TWAP_VALUE = 1e19;
    uint256 constant ORACLE_MIN_PRICE_DENOM = 10000;
    uint256 constant MAX_SUPPLY = 1e27; // the max supply of the options token & the underlying token

    address owner;
    address tokenAdmin;
    address treasury;

    OptionsToken optionsToken;
    BalancerOracle oracle;
    MockBalancerTwapOracle balancerTwapOracle;
    TestERC20Mintable paymentToken;
    ERC20 underlyingToken;

    function setUp() public {
        // set up accounts
        owner = makeAddr("owner");
        tokenAdmin = makeAddr("tokenAdmin");
        treasury = makeAddr("treasury");

        // deploy contracts
        balancerTwapOracle = new MockBalancerTwapOracle();
        oracle =
            new BalancerOracle(balancerTwapOracle, owner, ORACLE_MULTIPLIER, ORACLE_SECS, ORACLE_AGO, ORACLE_MIN_PRICE);
        paymentToken = new TestERC20Mintable();
        underlyingToken = ERC20(address(new TestERC20Mintable()));
        optionsToken =
        new OptionsToken("TIT Call Option Token", "oTIT", owner, tokenAdmin, paymentToken, underlyingToken, oracle, treasury);

        // set up contracts
        balancerTwapOracle.setTwapValue(ORACLE_INIT_TWAP_VALUE);
        paymentToken.approve(address(optionsToken), type(uint256).max);
        TestERC20Mintable(address(underlyingToken)).mint(address(optionsToken), type(uint).max);
    }

    function test_onlyTokenAdminCanMint(uint256 amount, address hacker) public {
        vm.assume(hacker != tokenAdmin);

        // try minting as non token admin
        vm.startPrank(hacker);
        vm.expectRevert(bytes4(keccak256("OptionsToken__NotTokenAdmin()")));
        optionsToken.mint(address(this), amount);
        vm.stopPrank();

        // mint as token admin
        vm.prank(tokenAdmin);
        optionsToken.mint(address(this), amount);

        // verify balance
        assertEqDecimal(optionsToken.balanceOf(address(this)), amount, 18);
    }

    function test_exerciseHappyPath(uint256 amount, address recipient) public {
        amount = bound(amount, 0, MAX_SUPPLY);

        // mint options tokens
        vm.prank(tokenAdmin);
        optionsToken.mint(address(this), amount);

        // mint payment tokens
        uint256 expectedPaymentAmount =
            amount.mulWadUp(ORACLE_INIT_TWAP_VALUE.mulDivUp(ORACLE_MULTIPLIER, ORACLE_MIN_PRICE_DENOM));
        paymentToken.mint(address(this), expectedPaymentAmount);

        // exercise options tokens
        uint256 actualPaymentAmount = optionsToken.exercise(amount, expectedPaymentAmount, recipient);

        // verify options tokens were transferred
        assertEqDecimal(optionsToken.balanceOf(address(this)), 0, 18, "user still has options tokens");
        assertEqDecimal(optionsToken.balanceOf(address(0)), amount, 18, "address(0) didn't get options tokens");
        assertEqDecimal(optionsToken.totalSupply(), amount, 18, "total supply changed");

        // verify payment tokens were transferred
        assertEqDecimal(paymentToken.balanceOf(address(this)), 0, 18, "user still has payment tokens");
        assertEqDecimal(
            paymentToken.balanceOf(treasury), expectedPaymentAmount, 18, "treasury didn't receive payment tokens"
        );
        assertEqDecimal(actualPaymentAmount, expectedPaymentAmount, 18, "exercise returned wrong value");
    }

    function test_exerciseMinPrice(uint256 amount, address recipient) public {
        amount = bound(amount, 0, MAX_SUPPLY);

        // mint options tokens
        vm.prank(tokenAdmin);
        optionsToken.mint(address(this), amount);

        // set TWAP value such that the strike price is below the oracle's minPrice value
        balancerTwapOracle.setTwapValue(0);

        // mint payment tokens
        uint256 expectedPaymentAmount = amount.mulWadUp(ORACLE_MIN_PRICE);
        paymentToken.mint(address(this), expectedPaymentAmount);

        // exercise options tokens
        uint256 actualPaymentAmount = optionsToken.exercise(amount, expectedPaymentAmount, recipient);

        // verify options tokens were transferred
        assertEqDecimal(optionsToken.balanceOf(address(this)), 0, 18, "user still has options tokens");
        assertEqDecimal(optionsToken.balanceOf(address(0)), amount, 18, "address(0) didn't get options tokens");
        assertEqDecimal(optionsToken.totalSupply(), amount, 18, "total supply changed");

        // verify payment tokens were transferred
        assertEqDecimal(paymentToken.balanceOf(address(this)), 0, 18, "user still has payment tokens");
        assertEqDecimal(
            paymentToken.balanceOf(treasury), expectedPaymentAmount, 18, "treasury didn't receive payment tokens"
        );
        assertEqDecimal(actualPaymentAmount, expectedPaymentAmount, 18, "exercise returned wrong value");
    }

    function test_exerciseOracleFails(uint amount, address recipient) public {
        amount = bound(amount, 0, MAX_SUPPLY);

        // mint options tokens
        vm.prank(tokenAdmin);
        optionsToken.mint(address(this), amount);

        // oracle should revert. This happens in the beginning of the deployment because the oracle
        // needs 1024 data entries before its initialized. Because we expect the initial volume and swap
        // frequency to be low, we need to enable exercising the OptionToken without having access to the oracle.
        // It will simply use the `minPrice` as the strike price until the oracle is fully initialized.
        balancerTwapOracle.setShouldRevert(true);

        // mint payment tokens
        uint256 expectedPaymentAmount = amount.mulWadUp(ORACLE_MIN_PRICE);
        paymentToken.mint(address(this), expectedPaymentAmount);

        // exercise options tokens
        uint256 actualPaymentAmount = optionsToken.exercise(amount, expectedPaymentAmount, recipient);

        // verify options tokens were transferred
        assertEqDecimal(optionsToken.balanceOf(address(this)), 0, 18, "user still has options tokens");
        assertEqDecimal(optionsToken.balanceOf(address(0)), amount, 18, "address(0) didn't get options tokens");
        assertEqDecimal(optionsToken.totalSupply(), amount, 18, "total supply changed");

        // verify payment tokens were transferred
        assertEqDecimal(paymentToken.balanceOf(address(this)), 0, 18, "user still has payment tokens");
        assertEqDecimal(
            paymentToken.balanceOf(treasury), expectedPaymentAmount, 18, "treasury didn't receive payment tokens"
        );
        assertEqDecimal(actualPaymentAmount, expectedPaymentAmount, 18, "exercise returned wrong value");
    }

    function testFork_oracleNotInitialized() public {
        // latest block at the time of this writing
        vm.createSelectFork(vm.envString("RPC_URL_GOERLI"), 9629719);
        // setup with forked environment:
        // the oracle will revert because it wasn't initialized yet.
        IBalancerTwapOracle pool = IBalancerTwapOracle(0x29d7a7E0d781C957696697B94D4Bc18C651e358E);
        paymentToken = new TestERC20Mintable();
        underlyingToken = ERC20(address(new TestERC20Mintable()));
        oracle = new BalancerOracle(pool, owner, ORACLE_MULTIPLIER, ORACLE_SECS, ORACLE_AGO, ORACLE_MIN_PRICE);
        optionsToken = new OptionsToken("TIT Call Option Token", "oTIT", owner, tokenAdmin, paymentToken, underlyingToken, oracle, treasury);
        paymentToken.approve(address(optionsToken), type(uint256).max);
        TestERC20Mintable(address(underlyingToken)).mint(address(optionsToken), type(uint).max);

        uint amount = 1e18;
        // mint options tokens
        vm.prank(tokenAdmin);
        optionsToken.mint(address(this), amount);


        // mint payment tokens
        uint256 expectedPaymentAmount = amount.mulWadUp(ORACLE_MIN_PRICE);
        paymentToken.mint(address(this), expectedPaymentAmount);

        // exercise options tokens
        uint256 actualPaymentAmount = optionsToken.exercise(amount, expectedPaymentAmount, address(this));

        // verify options tokens were transferred
        assertEqDecimal(optionsToken.balanceOf(address(this)), 0, 18, "user still has options tokens");
        assertEqDecimal(optionsToken.balanceOf(address(0)), amount, 18, "address(0) didn't get options tokens");
        assertEqDecimal(optionsToken.totalSupply(), amount, 18, "total supply changed");

        // verify payment tokens were transferred
        assertEqDecimal(paymentToken.balanceOf(address(this)), 0, 18, "user still has payment tokens");
        assertEqDecimal(
            paymentToken.balanceOf(treasury), expectedPaymentAmount, 18, "treasury didn't receive payment tokens"
        );
        assertEqDecimal(actualPaymentAmount, expectedPaymentAmount, 18, "exercise returned wrong value");
    }

    function test_exerciseHighSlippage(uint256 amount, address recipient) public {
        amount = bound(amount, 1, MAX_SUPPLY);

        // mint options tokens
        vm.prank(tokenAdmin);
        optionsToken.mint(address(this), amount);

        // mint payment tokens
        uint256 expectedPaymentAmount =
            amount.mulWadUp(ORACLE_INIT_TWAP_VALUE.mulDivUp(ORACLE_MULTIPLIER, ORACLE_MIN_PRICE_DENOM));
        paymentToken.mint(address(this), expectedPaymentAmount);

        // exercise options tokens which should fail
        vm.expectRevert(bytes4(keccak256("OptionsToken__SlippageTooHigh()")));
        optionsToken.exercise(amount, expectedPaymentAmount - 1, recipient);
    }

    function test_exerciseTwapOracleNotReady(uint256 amount, address recipient) public {
        amount = bound(amount, 1, MAX_SUPPLY);

        // mint options tokens
        vm.prank(tokenAdmin);
        optionsToken.mint(address(this), amount);

        // mint payment tokens
        uint256 expectedPaymentAmount =
            amount.mulWadUp(ORACLE_INIT_TWAP_VALUE.mulDivUp(ORACLE_MULTIPLIER, ORACLE_MIN_PRICE_DENOM));
        paymentToken.mint(address(this), expectedPaymentAmount);

        // update oracle params
        // such that the TWAP window becomes (block.timestamp - ORACLE_LARGEST_SAFETY_WINDOW - ORACLE_SECS, block.timestamp - ORACLE_LARGEST_SAFETY_WINDOW]
        // which is outside of the largest safety window
        vm.prank(owner);
        oracle.setParams(ORACLE_MULTIPLIER, ORACLE_SECS, ORACLE_LARGEST_SAFETY_WINDOW, ORACLE_MIN_PRICE);

        // exercise options tokens which should fail
        vm.expectRevert(bytes4(keccak256("BalancerOracle__TWAPOracleNotReady()")));
        optionsToken.exercise(amount, expectedPaymentAmount, recipient);
    }

    function test_exercisePastDeadline(uint256 amount, address recipient, uint256 deadline) public {
        amount = bound(amount, 0, MAX_SUPPLY);
        deadline = bound(deadline, 0, block.timestamp - 1);

        // mint options tokens
        vm.prank(tokenAdmin);
        optionsToken.mint(address(this), amount);

        // mint payment tokens
        uint256 expectedPaymentAmount =
            amount.mulWadUp(ORACLE_INIT_TWAP_VALUE.mulDivUp(ORACLE_MULTIPLIER, ORACLE_MIN_PRICE_DENOM));
        paymentToken.mint(address(this), expectedPaymentAmount);

        // exercise options tokens
        vm.expectRevert(bytes4(keccak256("OptionsToken__PastDeadline()")));
        optionsToken.exercise(amount, expectedPaymentAmount, recipient, deadline);
    }
}
