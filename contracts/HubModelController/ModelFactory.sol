pragma solidity ^0.4.18;

import "./interfaces/ModelFactoryInterface.sol";
import "./Model.sol";


contract ModelFactory is ModelFactoryInterface {
  // Allow other controllers to use this interface to create tree-like structure
  function instantiateModel (address _controller_address) public returns (address) {
    return new Model(msg.sender, _controller_address);
  }
}
