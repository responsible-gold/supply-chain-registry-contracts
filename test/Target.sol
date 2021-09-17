pragma solidity ^0.4.2;

contract Target {
  address owner;
  uint public counter = 0;
  uint public counterPrecise = 0;
  byte public param;

  modifier onlyOwner() {
    if (msg.sender != owner)
      throw;
    _;
  }

  function Target(address _owner) {
    owner = _owner;
  }

  function count() onlyOwner {
    counter++;
  }

  function countPrecise() onlyOwner {
    counterPrecise++;
  }

  function setParam(byte _newParam) onlyOwner {
    param = _newParam;
  }
}
