// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/staking/CelluxStaking.sol";
import "../src/token/CelluxToken.sol";
import "../src/token/MockUSDC.sol";

contract CelluxStakingTest is Test {
    CelluxStaking public staking;
    CelluxToken public cellux;
    MockUSDC public usdc;

    address public owner;
    address public user1;
    address public user2;
    address public user3;
    address public rewardDistributor;

    // Test addresses for token distribution
    address public treasury;
    address public team;
    address public stakingRewards;
    address public liquidityMining;

    uint256 constant STAKE_AMOUNT = 1000e18; // 1000 CELL
    uint256 constant MIN_STAKE = 1e18; // 1 CELL
    uint256 constant REWARD_AMOUNT = 10000e6; // 10000 USDC

    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 penalty, uint256 timestamp);
    event RewardsClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event RewardsAdded(uint256 amount, uint256 timestamp);
    event ParametersUpdated(uint256 minStakeAmount, uint256 lockPeriod, uint256 earlyUnstakePenaltyBps);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        rewardDistributor = makeAddr("rewardDistributor");

        // Setup token distribution addresses
        treasury = makeAddr("treasury");
        team = makeAddr("team");
        stakingRewards = makeAddr("stakingRewards");
        liquidityMining = makeAddr("liquidityMining");

        // Deploy tokens
        cellux = new CelluxToken();
        usdc = new MockUSDC(10000000e6); // 10M USDC

        // Initialize CELL token
        cellux.initialize(treasury, team, stakingRewards, liquidityMining);

        // Deploy staking contract
        staking = new CelluxStaking(address(cellux), address(usdc));

        // Transfer CELL to users for testing
        vm.startPrank(stakingRewards);
        cellux.transfer(user1, 10000e18);
        cellux.transfer(user2, 10000e18);
        cellux.transfer(user3, 10000e18);
        vm.stopPrank();

        // Mint USDC to reward distributor
        usdc.mint(rewardDistributor, 1000000e6);
    }

    /*//////////////////////////////////////////////////////////////
                            DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function testDeployment() public view {
        assertEq(address(staking.celluxToken()), address(cellux));
        assertEq(address(staking.usdc()), address(usdc));
        assertEq(staking.owner(), owner);
        assertEq(staking.minStakeAmount(), 1e18);
        assertEq(staking.lockPeriod(), 7 days);
        assertEq(staking.earlyUnstakePenaltyBps(), 1000); // 10%
        assertEq(staking.totalStaked(), 0);
    }

    function testDeployment_InvalidCellux() public {
        vm.expectRevert("CelluxStaking: Invalid CELL");
        new CelluxStaking(address(0), address(usdc));
    }

    function testDeployment_InvalidUsdc() public {
        vm.expectRevert("CelluxStaking: Invalid USDC");
        new CelluxStaking(address(cellux), address(0));
    }

    /*//////////////////////////////////////////////////////////////
                            STAKING TESTS
    //////////////////////////////////////////////////////////////*/

    function testStake() public {
        vm.startPrank(user1);
        cellux.approve(address(staking), STAKE_AMOUNT);

        vm.expectEmit(true, false, false, true);
        emit Staked(user1, STAKE_AMOUNT, block.timestamp);

        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        (uint256 amount,, uint256 stakedAt,) = staking.getUserStakeInfo(user1);
        assertEq(amount, STAKE_AMOUNT);
        assertEq(stakedAt, block.timestamp);
        assertEq(staking.totalStaked(), STAKE_AMOUNT);
    }

    function testStake_Multiple() public {
        vm.startPrank(user1);
        cellux.approve(address(staking), STAKE_AMOUNT * 3);

        staking.stake(STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        vm.stopPrank();

        (uint256 amount,,,) = staking.getUserStakeInfo(user1);
        assertEq(amount, STAKE_AMOUNT * 3);
        assertEq(staking.totalStaked(), STAKE_AMOUNT * 3);
    }

    function testStake_MultipleUsers() public {
        // User1 stakes
        vm.startPrank(user1);
        cellux.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        // User2 stakes
        vm.startPrank(user2);
        cellux.approve(address(staking), STAKE_AMOUNT * 2);
        staking.stake(STAKE_AMOUNT * 2);
        vm.stopPrank();

        // User3 stakes
        vm.startPrank(user3);
        cellux.approve(address(staking), STAKE_AMOUNT / 2);
        staking.stake(STAKE_AMOUNT / 2);
        vm.stopPrank();

        (uint256 amount1,,,) = staking.getUserStakeInfo(user1);
        (uint256 amount2,,,) = staking.getUserStakeInfo(user2);
        (uint256 amount3,,,) = staking.getUserStakeInfo(user3);

        assertEq(amount1, STAKE_AMOUNT);
        assertEq(amount2, STAKE_AMOUNT * 2);
        assertEq(amount3, STAKE_AMOUNT / 2);
        assertEq(staking.totalStaked(), STAKE_AMOUNT * 3 + STAKE_AMOUNT / 2);
    }

    function testStake_BelowMinimum() public {
        vm.startPrank(user1);
        cellux.approve(address(staking), MIN_STAKE - 1);

        vm.expectRevert("CelluxStaking: Below minimum stake");
        staking.stake(MIN_STAKE - 1);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            UNSTAKING TESTS
    //////////////////////////////////////////////////////////////*/

    function testUnstake_AfterLockPeriod() public {
        // Stake
        vm.startPrank(user1);
        cellux.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Fast forward past lock period
        vm.warp(block.timestamp + 7 days + 1);

        uint256 balanceBefore = cellux.balanceOf(user1);

        vm.expectEmit(true, false, false, true);
        emit Unstaked(user1, STAKE_AMOUNT, 0, block.timestamp);

        staking.unstake(STAKE_AMOUNT);
        vm.stopPrank();

        uint256 balanceAfter = cellux.balanceOf(user1);
        assertEq(balanceAfter - balanceBefore, STAKE_AMOUNT);
        assertEq(staking.totalStaked(), 0);
    }

    function testUnstake_EarlyWithPenalty() public {
        // Stake
        vm.startPrank(user1);
        cellux.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Unstake before lock period (should incur 10% penalty)
        uint256 expectedPenalty = (STAKE_AMOUNT * 1000) / 10000; // 10%
        uint256 expectedReturn = STAKE_AMOUNT - expectedPenalty;

        uint256 balanceBefore = cellux.balanceOf(user1);
        uint256 ownerBalanceBefore = cellux.balanceOf(owner);

        vm.expectEmit(true, false, false, true);
        emit Unstaked(user1, STAKE_AMOUNT, expectedPenalty, block.timestamp);

        staking.unstake(STAKE_AMOUNT);
        vm.stopPrank();

        uint256 balanceAfter = cellux.balanceOf(user1);
        uint256 ownerBalanceAfter = cellux.balanceOf(owner);

        assertEq(balanceAfter - balanceBefore, expectedReturn);
        assertEq(ownerBalanceAfter - ownerBalanceBefore, expectedPenalty);
    }

    function testUnstake_Partial() public {
        // Stake
        vm.startPrank(user1);
        cellux.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        // Fast forward past lock period
        vm.warp(block.timestamp + 7 days + 1);

        // Unstake half
        staking.unstake(STAKE_AMOUNT / 2);
        vm.stopPrank();

        (uint256 amount,,,) = staking.getUserStakeInfo(user1);
        assertEq(amount, STAKE_AMOUNT / 2);
        assertEq(staking.totalStaked(), STAKE_AMOUNT / 2);
    }

    function testUnstake_InvalidAmount() public {
        vm.prank(user1);
        vm.expectRevert("CelluxStaking: Invalid amount");
        staking.unstake(0);
    }

    function testUnstake_InsufficientStake() public {
        vm.startPrank(user1);
        cellux.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        vm.expectRevert("CelluxStaking: Insufficient stake");
        staking.unstake(STAKE_AMOUNT + 1);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            REWARDS TESTS
    //////////////////////////////////////////////////////////////*/

    function testAddRewards() public {
        // First stake to have stakers
        vm.startPrank(user1);
        cellux.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        // Add rewards
        vm.startPrank(rewardDistributor);
        usdc.approve(address(staking), REWARD_AMOUNT);

        vm.expectEmit(false, false, false, true);
        emit RewardsAdded(REWARD_AMOUNT, block.timestamp);

        staking.addRewards(REWARD_AMOUNT);
        vm.stopPrank();

        // Check accumulated rewards
        uint256 pending = staking.getPendingRewards(user1);
        assertEq(pending, REWARD_AMOUNT);
    }

    function testAddRewards_NoStakers() public {
        vm.startPrank(rewardDistributor);
        usdc.approve(address(staking), REWARD_AMOUNT);

        vm.expectRevert("CelluxStaking: No stakers");
        staking.addRewards(REWARD_AMOUNT);

        vm.stopPrank();
    }

    function testAddRewards_InvalidAmount() public {
        // Stake first
        vm.startPrank(user1);
        cellux.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        vm.prank(rewardDistributor);
        vm.expectRevert("CelluxStaking: Invalid amount");
        staking.addRewards(0);
    }

    function testClaimRewards() public {
        // Stake
        vm.startPrank(user1);
        cellux.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);
        vm.stopPrank();

        // Add rewards
        vm.startPrank(rewardDistributor);
        usdc.approve(address(staking), REWARD_AMOUNT);
        staking.addRewards(REWARD_AMOUNT);
        vm.stopPrank();

        // Claim rewards
        uint256 balanceBefore = usdc.balanceOf(user1);

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(user1, REWARD_AMOUNT, block.timestamp);

        staking.claimRewards();

        uint256 balanceAfter = usdc.balanceOf(user1);
        assertEq(balanceAfter - balanceBefore, REWARD_AMOUNT);
        assertEq(staking.totalRewardsDistributed(), REWARD_AMOUNT);
    }

    function testClaimRewards_NoRewards() public {
        // Stake but no rewards added
        vm.startPrank(user1);
        cellux.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT);

        vm.expectRevert("CelluxStaking: No rewards to claim");
        staking.claimRewards();

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        PARAMETER UPDATE TESTS
    //////////////////////////////////////////////////////////////*/

    function testUpdateParameters() public {
        uint256 newMinStake = 10e18;
        uint256 newLockPeriod = 14 days;
        uint256 newPenalty = 1500; // 15%

        vm.expectEmit(false, false, false, true);
        emit ParametersUpdated(newMinStake, newLockPeriod, newPenalty);

        staking.updateParameters(newMinStake, newLockPeriod, newPenalty);

        assertEq(staking.minStakeAmount(), newMinStake);
        assertEq(staking.lockPeriod(), newLockPeriod);
        assertEq(staking.earlyUnstakePenaltyBps(), newPenalty);
    }

    function testUpdateParameters_InvalidMinStake() public {
        vm.expectRevert("CelluxStaking: Invalid min stake");
        staking.updateParameters(0, 7 days, 1000);
    }

    function testUpdateParameters_LockTooLong() public {
        vm.expectRevert("CelluxStaking: Lock too long");
        staking.updateParameters(1e18, 91 days, 1000);
    }

    function testUpdateParameters_PenaltyTooHigh() public {
        vm.expectRevert("CelluxStaking: Penalty too high");
        staking.updateParameters(1e18, 7 days, 2501); // > 25%
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY WITHDRAW TESTS
    //////////////////////////////////////////////////////////////*/

    function testEmergencyWithdraw() public {
        // Send some USDC to staking contract
        usdc.mint(address(staking), 1000e6);

        uint256 balanceBefore = usdc.balanceOf(owner);

        staking.emergencyWithdraw(address(usdc), owner, 1000e6);

        uint256 balanceAfter = usdc.balanceOf(owner);
        assertEq(balanceAfter - balanceBefore, 1000e6);
    }

    function testEmergencyWithdraw_InvalidToken() public {
        vm.expectRevert("CelluxStaking: Invalid token");
        staking.emergencyWithdraw(address(0), owner, 100e6);
    }

    function testEmergencyWithdraw_InvalidAddress() public {
        vm.expectRevert("CelluxStaking: Invalid address");
        staking.emergencyWithdraw(address(usdc), address(0), 100e6);
    }

    function testEmergencyWithdraw_InvalidAmount() public {
        vm.expectRevert("CelluxStaking: Invalid amount");
        staking.emergencyWithdraw(address(usdc), owner, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_Stake(uint256 amount) public {
        amount = bound(amount, MIN_STAKE, 10000e18);

        vm.startPrank(user1);
        cellux.approve(address(staking), amount);
        staking.stake(amount);
        vm.stopPrank();

        (uint256 stakedAmount,,,) = staking.getUserStakeInfo(user1);
        assertEq(stakedAmount, amount);
    }
}
