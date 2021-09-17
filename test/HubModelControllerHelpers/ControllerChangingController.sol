pragma solidity "^0.4.18";

import "../../contracts/HubModelController/abstracts/ControllerAbstract.sol";
import "../../contracts/HubModelController/Manageable.sol";


contract ControllerChangingController is ControllerAbstract, Manageable {

  //
  function ControllerChangingController () public Manageable(0) {

  }

  function constructDelegate (address _model_address) public onlyOrg {
    ControllerChangingController(_model_address).constructor(msg.sender);
  }

  function constructor (address _organization)
    public
    onlyController
    onlyOnce(msg.sig)
  {
    super.manageableConstructor(_organization);
  }

  function setNewController (address _model_address, address _new_controller_address) {
    ModelInterface(_model_address).modelSetController(_new_controller_address);
  }

  function setNewControllerPermissioned (address _model_address, address _new_controller_address) onlyOrg {
    ModelInterface(_model_address).modelSetController(_new_controller_address);
  }
}
