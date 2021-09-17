pragma solidity ^0.4.18;

import "./interfaces/HubInterface.sol";
import "./interfaces/ModelFactoryInterface.sol";
import "./interfaces/ModelInterface.sol";
import "./Manageable.sol";


// Only one instance exists for the whole "universe"
contract Hub is HubInterface, Manageable {
  ModelFactoryInterface modelFactory;
  struct ModelMeta {
    address model_address;
    uint name_index;
  }
  mapping (bytes32 => ModelMeta) name_to_meta;
  bytes32[] model_names;


  modifier modelNameAvailable (bytes32 _name) {
    require(name_to_meta[_name].model_address == 0);
    _;
  }

  modifier modelNameExists (bytes32 _name) {
    require(name_to_meta[_name].model_address != 0);
    _;
  }

  function Hub (address _model_factory_address) public Manageable(0) {
    setModelFactory(_model_factory_address);
  }

  // TODO: constant call to instantiateModel() to see if it's there
  function setModelFactory (address _new_address) public onlyOrg {
    require(_new_address != address(0));

    ModelFactoryUpdated(_new_address);
    modelFactory = ModelFactoryInterface(_new_address);
  }


  // For other controllers to re-use
  function getModelFactory () public constant returns (address _address) {
    return modelFactory;
  }

  // CRUD for models
  function createModel (bytes32 _name, address _controller_address)
    public
    onlyOrg
    modelNameAvailable(_name)
    returns (address)
  {
    address _model_address = modelFactory.instantiateModel(_controller_address);
    assert(_model_address != 0);

    ModelCreated(_name, _model_address);
    name_to_meta[_name] = ModelMeta(_model_address, model_names.length);
    model_names.push(_name);

    return _model_address;
  }

  function getModelAddress (bytes32 _name) public constant returns (address _address) {
    return name_to_meta[_name].model_address;
  }

  function getModelNames () public constant returns (bytes32[] _names) {
    return model_names;
  }

  function setModelController (bytes32 _name, address _new_controller_address)
    public
    onlyOrg
    modelNameExists(_name)
    returns (bool)
  {
    return ModelInterface(getModelAddress(_name)).modelSetController(_new_controller_address);
  }

  // Remove from hub pointer, but leave "cleaning up" part and decision to the controller
  function rmModel (bytes32 _name, bytes32 _optional_reason)
    public
    onlyOrg
    modelNameExists(_name)
  {
    ModelRemoved(_name, _optional_reason);

    uint _index = name_to_meta[_name].name_index;
    delete name_to_meta[_name];

    if (model_names.length > 1) {
      model_names[_index] = model_names[model_names.length - 1];
      name_to_meta[model_names[_index]].name_index = _index;
    }
    model_names.length--;
  }

  // No modelSetOutputLength, maybe this will be removed
}
