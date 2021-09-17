pragma solidity ^0.4.18;

// All methods prefixed with "model" to mitigate collisions with controller's methods
// outsourcing this methods into external contract will impose costly CALL expenses
// which is intended to be reduced by this approach
interface ModelInterface {
  modifier onlyModelOwner() {_;}

  event ModelControllerSet (address _new_controller_address);

  // Controller
  function modelSetController (address _controller_address) external onlyModelOwner returns (bool);
  function modelGetController () public constant returns (address);

  // Default output length, controller-wise
  function modelSetOutputLengthDefault (uint32 _length) public onlyModelOwner();
  function modelGetOutputLengthDefault () public constant returns (uint32);

  // Output lengths
  function modelSetOutputLength (bytes4 _method_signature, uint32 _length) public onlyModelOwner returns (bool);
  function modelGetOutputLength (bytes4 _method_signature) public constant returns (uint32);

  // Relay to controller
  function() public;
}
