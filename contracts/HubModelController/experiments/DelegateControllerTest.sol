pragma solidity ^0.4.18;

contract DelegateControllerTest {}

contract Dispatcher {
    address target;
    function Dispatcher (address _target) {
        target = _target;
        // hub = msg.sender;
    }

    // dispatcherSetTarget() onlyHub
    // dispatcherSetOutputLen() onlyHubOrController


  function() {
    uint32 _len = 102400;
    address _target = target;


    assembly {
      calldatacopy(0x0, 0x0, calldatasize)
      let a := delegatecall(sub(gas, 10000), _target, 0x0, calldatasize, 0, _len)
      return(0, _len)
    }
  }
}
// Dynamically ask output size


contract Controller {
    function getBytes1() returns (bytes1, bytes32[4]) {
        bytes32[4] memory array;
        array[0] = 0x01;
        array[1] = 0x02;
        array[2] = 0x03;
        array[3] = 0x04;
        return (0x77, array);
    }
}

contract Caller {
    Controller controller;
    function Caller (address dispatcher) {
        controller = Controller(dispatcher);
    }

    function call () returns (bytes1, bytes32[4]) {
        bytes1 a;
        // bytes32[] memory b;
        return controller.getBytes1();
    }
}
