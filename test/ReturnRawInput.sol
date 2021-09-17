pragma solidity ^0.4.18;

// Report the msg.data
// Provide return data that is sufficient to identify the return length
contract ReturnRawInput {
  function() public {
    assembly {
      calldatacopy(0x0, 0x0, calldatasize)
      return(0x0, calldatasize)
    }
  }

  // adbee694
  function solidityReturnDynamic(bytes32 _input0, bytes32 _input1) returns (bytes) {
    return msg.data;
  }

  // ec5b4d3b
  function solidityReturnBytes32(bytes32 _input0, bytes32 _input1) returns (bytes32, bytes32, bytes32) {
    bytes32 _result0;
    bytes32 _result1;
    assembly {
      calldatacopy(0x0, 0x0, 0x40)
      _result0 := mload(0x0)
      _result1 := mload(0x20)
    }
    // Offset by 32bytes of FF.. to differentiate from data written in the same slot of memory
    return (-1, _result0, _result1);
  }
}
