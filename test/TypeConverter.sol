pragma solidity ^0.4.2;

import "./Debug.sol";


contract TypeConverter is Debug {
  function _toBytes (bytes32 _input, uint _len) internal returns (bytes) {
    bytes memory _res = new bytes(_len);
    for (uint _i = 0; _i < _len; _i++) {
      _res[_i] = _input[_i];
    }
    return _res;
  }

  function toBytes (bytes32 _input, uint _len) returns (bytes) {
    return _toBytes(_input, _len);
  }

  function concatBytes (bytes _a, bytes _b) returns (bytes) {
    bytes memory _res = new bytes(_a.length + _b.length);
    for (uint _i = 0; _i < _a.length; _i++) {
      _res[_i] = _a[_i];
    }

    for (uint _j = 0; _j < _b.length; _j++) {
      _res[_i + _j] = _b[_j];
    }
    return _res;
  }

  function repeatBytes (bytes _to_repeat, uint _times) returns (bytes) {
    bytes memory _res = new bytes(_to_repeat.length * _times);
    for (uint _time = 0; _time < _times; _time++) {
      for (uint _i = 0; _i < _to_repeat.length; _i++) {
        _res[_time * _to_repeat.length + _i] = _to_repeat[_i];
      }
    }
    return _res;
  }

  /*function toBytes(bytes4 _input) returns (bytes) {
    return _toBytes(_input, 4);
  }*/

  function bytesToHexString(bytes value) returns (string) {
    bytes memory hex_chars = "0123456789abcdef";
    DebugUInt(hex_chars.length);
    DebugString(string(hex_chars));
    bytes memory hstr = new bytes(value.length * 2 + 2);
    hstr[0] = "0";
    hstr[1] = "x";
    for (uint i; i < value.length; i++) {
      hstr[2 + i * 2]     = hex_chars[uint8(value[i]) / 0x10];
      hstr[2 + i * 2 + 1] = hex_chars[uint8(value[i]) % 0x10];
    }
    return string(hstr);
  }
}
