pragma solidity ^0.4.18;

import "./Debug.sol";
import "truffle/Assert.sol";

contract Caller is Debug {
  uint32 currentLength;
  address currentTarget;
  bytes lastOutput;

  function callAndReturn (address _target, bytes _data, uint32 _output_len) returns (bytes) {
    currentTarget = _target;
    currentLength = _output_len;
    LogBytes("Caller data", _data);
    bool call_res = address(this).delegatecall(_data);
    LogBool("Caller res", call_res);
    return lastOutput;
  }

  function() public {
    DebugString("Caller Fallback");
    uint32 _len = currentLength;
    address _target = currentTarget;

    bytes memory _output = new bytes(_len);

    assembly {
      calldatacopy(mload(0x40), 0x0, calldatasize)
      let r := call(sub(gas, 10000), _target, 0x0, mload(0x40), calldatasize, add(_output, 0x20), _len)
    }

    LogBytes("Caller output", _output);

    lastOutput = _output;
    //assembly {
    //  return(mload(0x40), _len)
    //}
  }

  function sig(string _methodSignature) public returns (bytes4) {
    return bytes4(keccak256(_methodSignature));
  }
}
