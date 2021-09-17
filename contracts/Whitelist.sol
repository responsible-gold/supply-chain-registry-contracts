pragma solidity ^0.4.2;

contract Whitelist {
  // State
  address owner;
  mapping(address => bool) addresses;

  // Modifiers
  modifier onlyOwner {
    if (owner == msg.sender) _;
  }

  modifier notWhitelisted(address _address) {
    if (!addresses[_address]) _;
  }

  modifier whitelisted(address _address) {
    if (addresses[_address]) _;
  }

  // Events
  event AddressAdded(address _address);
  event AddressRemoved(address _address);

  function Whitelist(address[] _addresses) {
    owner = msg.sender;

    for (uint _index = 0; _index < _addresses.length; _index++) {
      add(_addresses[_index]);
    }
  }

  function add(address _address)
  onlyOwner
  notWhitelisted(_address)
  returns (bool) {
    addresses[_address] = true;
    AddressAdded(_address);
    return true;
  }

  function remove(address _address)
  onlyOwner
  whitelisted(_address)
  returns (bool) {
    delete addresses[_address];
    AddressRemoved(_address);
    return true;
  }

  // Readonly
  function isWhitelisted(address _address) constant returns (bool) {
    return addresses[_address];
  }
}
