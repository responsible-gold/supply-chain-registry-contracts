pragma solidity ^0.4.18;

import "./Debug.sol";
import "./TypeConverter.sol";


contract ProxyAccount is Debug, TypeConverter {
  address public destination;

  function ProxyAccount (address _destination) {
    destination = _destination;
  }

  function setDestination (address _destination) {
    destination = _destination;
  }

  function execute(address _to, bytes _data) public {
    if (!_to.call(_data)) {
      DebugString("CALL has thrown");
    }
  }

  function executeRaw(bytes32 _data) public {
    if (!destination.call(_data)) {
      DebugString("CALL has thrown");
    }
  }

  function executeRaw(bytes _data) public {
    if (!destination.call(_data)) {
      DebugString("CALL has thrown");
    }
  }

  function executeAndResult (address _to, bytes _data) public returns (bool) {
    return _to.call.gas(5000000)(_data);
  }

  function executeAndResult (bytes _data) public returns (bool) {
    return destination.call.gas(5000000)(_data);
  }

  function executeAndResult (bytes4 _data) public returns (bool) {
    return destination.call.gas(5000000)(_data);
  }

  function executeAndResult (bytes4 _data, bytes32 _input0, bytes32 _input1) public returns (bool) {
    return destination.call.gas(5000000)(_data, _input0, _input1);
  }

  function() public {
    uint32 _len = 1024;
    /*bool a;*/
    bool r;


    assembly {
      calldatacopy(mload(0x40), 0x0, calldatasize)
      r := call(sub(gas, 10000), sload(destination_slot), 0, mload(0x40), calldatasize, mload(0x40), _len)
      // returned := mload(0x0)
      switch r
      case 1 {
        return(mload(0x40), _len)
      }
      case 0 {
        /*invalid*/
      }
    }
    LogBytes("Proxy call failed", msg.data);
    // LogBytes32("CALL returned (32 bytes):", returned);
  }
}
