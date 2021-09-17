pragma solidity ^0.4.18;

import "../interfaces/ManageableInterface.sol";


// Important: Controller must include variables as first in the contract
// to signify and protect first 4 storage spots
// Also for optional re-use in controller
contract ModelVariables {
  ManageableInterface hub;
  address public model_controller;
  // signature hash => output length, max value interpreted as 0 length to avoid
  // confusion with default var value 0.
  mapping (bytes4 => uint32) model_output_lengths;
  uint32 public model_output_length_default = 32 * 16;
}
