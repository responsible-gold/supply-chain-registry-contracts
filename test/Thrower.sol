pragma solidity "^0.4.18";

contract Thrower {
  function _throw () { // 90446765
    throw;
  }

  function _assert () { // 0d8ab88f
    assert(false);
  }

  function _require () { // be17e373
    require(false);
  }

  function ok () returns (bool) { // d909b403
    return true;
  }
}
