pragma solidity ^0.4.18;


interface ModelFactoryInterface {
  // Allow other controllers to use this interface to create tree-like structure
  function instantiateModel (address _controller_address) public returns (address);
}
