pragma solidity ^0.4.18;

import "./ModelVariables.sol";
import "../interfaces/ModelInterface.sol";

// Reusable interface for controllers
// Things to verify before assigning new controller:
//   - Controller doesn't have selfdestruct opcode
//   - Controller inherits either from ModelVariables abstract class or
//     from previous class.
//   - Controller doesn't manipulate any of the ModelVariables storage vars
//   - Controller doesn't use assembly that can modify first N (currently 4)
//     locations of the contract storage

contract ControllerAbstract is ModelVariables {
  // Optional ABI for the smart contract for easy discovery of capabilities
  string public abi;
  // Optional URL where controller's and other relevant documetation
  string public documentation_url;

  modifier onlyController {
    require(ModelInterface(this).modelGetController() == msg.sender);
    _;
  }

  mapping (bytes32 => bool) singleton_method_spent;
  modifier onlyOnce (bytes4 _method_sig) {
    // Allow to call the method only once per controller address
    bytes32 _method_id = keccak256(_method_sig, ModelInterface(this).modelGetController());
    require(singleton_method_spent[_method_id] == false);
    singleton_method_spent[_method_id] = true;
    _;
  }

  function controllerConstructor (string _abi, string _documentation_url) internal {
    abi = _abi;
    documentation_url = _documentation_url;
  }
}
