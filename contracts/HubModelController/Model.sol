pragma solidity ^0.4.18;

import "./ModelManagement.sol";


contract Model is ModelManagement {
  // Acknowledge: variable values can be overwritten by controller.
  // But it can destroy whole contract anyway. We assume it's non-malicious.

  function Model (address _hub_address, address _controller_address)
    public
    ModelManagement(_hub_address, _controller_address)
  {

  }

  // Relay to controller
  // TODO: increase gas if depending on the input length
  // BEWARE: if expected output length is longer than actual, extra will not be filled with 0s
  function() public {
    uint32 _len;
    uint32 _margin = 0; // Cannot use _offset
    // Flagging dynamic length input
    if (msg.sig == 0xffffffff) {
      _margin = 8;
      assembly {
        _len := div(calldataload(4), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
      }
    }
    else {
      _len = modelGetOutputLength(msg.sig);
    }

    assembly {
      let insize := sub(calldatasize, _margin)
      calldatacopy(mload(0x40), _margin, insize)
      let r := delegatecall(sub(gas, 0x2800), sload(model_controller_slot), mload(0x40), insize, mload(0x40), _len)

      switch r
      case 0 {
        revert(0, 0)
      }
      case 1 {
        return(mload(0x40), _len)
      }
    }
  }
}


// Modern version, available in Metropolis (already deployed) :
/*
calldatacopy(0x0, 0x0, calldatasize)
let r := delegatecall(sub(gas, 10000), _target, 0x0, calldatasize, 0x0, 0x0)
// jumpi(0x02, iszero(r))
returndatacopy(0, 0, returndatasize)
return(0, returndatasize)
*/
