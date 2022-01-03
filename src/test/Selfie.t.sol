// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../selfie/SelfiePool.sol";
import "../selfie/SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

contract SelfieAttacker {
    DamnValuableTokenSnapshot damnValuableTokenSnapshot;
    SimpleGovernance simpleGovernance;
    SelfiePool selfiePool;
    
    uint256 tokensInPool;

    constructor(address damnValuableTokenSnapshotAddress, 
                address simpleGovernanceAddress, 
                address selfiePoolAddress,
                uint256 totalTokens) {
        tokensInPool = totalTokens;
        damnValuableTokenSnapshot = DamnValuableTokenSnapshot(damnValuableTokenSnapshotAddress);
        simpleGovernance = SimpleGovernance(simpleGovernanceAddress);
        selfiePool = SelfiePool(selfiePoolAddress);
    }

    
    function attack() external { }
}

contract SelfieTest is DSTest {
    DamnValuableTokenSnapshot damnValuableTokenSnapshot;
    SimpleGovernance simpleGovernance;
    SelfiePool selfiePool;

    uint256 tokenInitialSupply = 2000000 ether;
    uint256 tokensInPool = 1500000 ether;

    function setUp() public {
        damnValuableTokenSnapshot = new DamnValuableTokenSnapshot(tokenInitialSupply);
        simpleGovernance = new SimpleGovernance(address(damnValuableTokenSnapshot));
        selfiePool = new SelfiePool(address(damnValuableTokenSnapshot), address(simpleGovernance));
        
        damnValuableTokenSnapshot.transfer(address(selfiePool), tokensInPool);
    }

    function testSelfie() public {
        SelfieAttacker attacker = new SelfieAttacker(address(damnValuableTokenSnapshot), 
                                                     address(simpleGovernance), 
                                                     address(selfiePool), 
                                                     tokensInPool);
        
        attacker.attack();

        require(damnValuableTokenSnapshot.balanceOf(address(attacker)) == tokensInPool);
        require(damnValuableTokenSnapshot.balanceOf(address(selfiePool)) == 0);
    }
}
