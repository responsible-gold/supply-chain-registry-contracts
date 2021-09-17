pragma solidity "^0.4.18";

import "truffle/Assert.sol";
import "./Debug.sol";
import "./TypeConverter.sol";

// Advanced
contract AssertAdv is Debug, TypeConverter {
  function equal(bytes A, bytes B, string message) constant returns (bool result) {
    return Assert.equal(bytesToHexString(A), bytesToHexString(B), message);
      /*result = _bytesEqual(A, B);
      if (result)
          _report(result, message);
      else
          _report(result, _appendTagged(_tag(A, "Tested"), _tag(B, "Against"), message));*/
  }

  function equal(bytes32 A, bytes32 B, string message) constant returns (bool result) {
    return Assert.equal(bytesToHexString(toBytes(A, 32)), bytesToHexString(toBytes(B, 32)), message);
  }

  /*function _bytesEqual(bytes ba, bytes bb) internal returns (bool result) {
      if (ba.length != bb.length)
          return false;
      for (uint i = 0; i < ba.length; i ++) {
          if (ba[i] != bb[i])
              return false;
      }
      return true;
  }*/

  /*function _tag(bytes value, string tag) internal returns (string) {
    return _tag(_hexToChars(value), tag);
  }*/

}
