pragma solidity ^0.4.18;

interface HubInterface {
  event ModelCreated (bytes32 name, address model_address);
  event ModelRemoved (bytes32 name, bytes32 optional_reason);
  event ModelFactoryUpdated (address model_factory_address);

  modifier onlyOrg {_;}
  modifier modelNameAvailable (bytes32 _name) {_;}
  modifier modelNameExists (bytes32 _name) {_;}

  // TODO: constant call to instantiateModel() to see if it's there
  function setModelFactory (address _address) public onlyOrg();
  // For others controllers to use
  function getModelFactory () public constant returns (address _address);

  // CRUD for models
  function createModel (bytes32 _name, address _controller_address) public onlyOrg modelNameAvailable(_name) returns(address);
  function getModelAddress (bytes32 _name) public constant returns (address _address);
  function getModelNames () public constant returns (bytes32[] _names);
  function setModelController (bytes32 _name, address _controller_address) public onlyOrg returns (bool);
  // Remove from hub pointer, but leave "cleaning up part and decision" to a controller
  function rmModel (bytes32 _name, bytes32 optional_reason) public onlyOrg modelNameExists(_name);
  // No getControllerAddress since factory can change, ask model
}
