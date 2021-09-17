pragma solidity ^0.4.18;

import "./interfaces/ModelInterface.sol";
import "./abstracts/ModelVariables.sol";

// TODO: collision-resistant prefix for vars, methods, events
// Doesn't use stoppable, since dummy controller can be assigned temporarily.
contract ModelManagement is ModelInterface, ModelVariables {
  event DebugBool(bool);

  modifier onlyModelOwner () {
    // Delegated controller can call as ModelInterface(this).modelSetController()
    // TODO: decide if model controller account can change controller msg.sender == model_controller
    //       controller instance isn't supposed to have state.

    DebugBool(hub.isOrganization(msg.sender));
    require(
      msg.sender == address(this) // external call of self, i.e. delegated contract (controller)
      || msg.sender == address(hub)
      || hub.isOrganization(msg.sender) // necessary for non-generic methods, as modelSetOutputLength()
      // || msg.sender == model_controller // controller's account
    );
    _;
  }

  function ModelManagement (address _hub_address, address _controller_address) public {
    hub = ManageableInterface(_hub_address);
    _modelSetControllerNoAuth(_controller_address);
  }

  function() public;

  // Controller
  function modelSetController (address _controller_address)
    external
    onlyModelOwner
    returns (bool)
  {
    return _modelSetControllerNoAuth(_controller_address);
  }

  function modelGetController () public constant returns (address) {
    return model_controller;
  }

  function modelSetOutputLengthDefault (uint32 _length) public onlyModelOwner {
    model_output_length_default = _length;
  }

  function modelGetOutputLengthDefault () public constant returns (uint32) {
    return model_output_length_default;
  }

  // Output lengths
  function modelSetOutputLength (bytes4 _method_signature, uint32 _length)
    public
    onlyModelOwner
    returns (bool)
  {
    model_output_lengths[_method_signature] = _length;
    return true;
  }

  function modelGetOutputLength (bytes4 _method_signature)
    public
    constant
    returns (uint32)
  {
    if (model_output_lengths[_method_signature] > 0) {
      return model_output_lengths[_method_signature] == uint32(-1)
        ? 0
        : model_output_lengths[_method_signature];
    }
    return model_output_length_default;
  }


  // INTERNAL
  function _modelSetControllerNoAuth (address _controller_address)
    internal
    returns (bool)
  {
    require(_controller_address != 0);
    require(_controller_address != address(this)); // Recursion

    // ?TODO: Verification if controller code has selfdestruct opcode
    ModelControllerSet(_controller_address);
    model_controller = _controller_address;
    return true;
  }
}
