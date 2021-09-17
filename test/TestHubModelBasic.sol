pragma solidity ^0.4.18;


import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/HubModelController/Hub.sol";
import "../contracts/HubModelController/ModelFactory.sol";
import "../contracts/HubModelController/abstracts/ControllerAbstract.sol";
import "./Debug.sol";
import "./Caller.sol";
import "./TypeConverter.sol";
import "./ProxyAccount.sol";
import "./AssertAdv.sol";
import "./HubModelControllerHelpers/ControllerChangingController.sol";

contract TestHubModelBasic is Debug, TypeConverter, Caller, AssertAdv {

  // TODO: granular testing of components
  // - Manageable tests
  function testGeneralScenario () {
    DummyController controller = new DummyController();

    ModelFactory modelFactory = new ModelFactory();
    Assert.notEqual(modelFactory.instantiateModel(controller), 0x0, "Empty model address");

    Hub hub = new Hub(modelFactory);
    hub.createModel("Dummy", controller);
    address model_address = hub.getModelAddress("Dummy");
    Assert.notEqual(model_address, 0x0, "Dummy model address is empty");

    Assert.equal(ModelInterface(model_address).modelGetController(), controller, "Controller address is incorrect");

    var dummyController = DummyController(model_address);
    Assert.equal(dummyController.get(), 0, "");
    dummyController.set(73);
    Assert.equal(dummyController.get(), 73, "");
  }

  function testControllerVersionUpdate () {
    DummyController controller = new DummyController();
    ModelFactory modelFactory = new ModelFactory();
    Hub hub = new Hub(modelFactory);
    hub.createModel("Dummy", controller);
    address model_address = hub.getModelAddress("Dummy");

    Assert.equal(DummyController(model_address).get(), 0, "Initial value is zero");
    DummyController(model_address).set(4);
    Assert.equal(DummyController(model_address).get(), 4, "Update to 4 is reflected");

    hub.setModelController("Dummy", new DummyControllerLogic());
    Assert.equal(DummyControllerLogic(model_address).get(), 4, "Data stayed the same");
    DummyControllerLogic(model_address).set(5);
    Assert.equal(DummyControllerLogic(model_address).get(), 15, "Logic updated");

    hub.setModelController("Dummy", new DummyControllerNewData());
    var (a, b) = DummyControllerNewData(model_address).getV2();
    Assert.equal(a, 15, "Data updated");
    Assert.equal(b, 0, "Initial value");
    DummyControllerNewData(model_address).set(7);
    (a, b) = DummyControllerNewData(model_address).getV2();
    Assert.equal(a, 21, "Data logic affected");
    Assert.equal(b, 28, "Data logic affected");

    hub.setModelController("Dummy", new DummyControllerMethod());
    DummyControllerMethod(model_address).set(5, 3);
    (a, b) = DummyControllerNewData(model_address).getV2();
    Assert.equal(a, 15, "Method has changed");
    Assert.equal(b, 3, "Method has changed");

    hub.setModelController("Dummy", new DummyControllerMethodRemoveData());
    DummyControllerMethodRemoveData(model_address).set(16);
    Assert.equal(DummyControllerMethodRemoveData(model_address).get(), 16, "Data is removed");
  }

  function testControllerAddressUpdate () {
    // from Hub, delegeated Controller, Hub's owner
    ModelFactory modelFactory = new ModelFactory();
    Hub hub = new Hub(modelFactory);
    bytes32 CONTROLLER_NAME = "Controller";

    hub.createModel(CONTROLLER_NAME, 0x101);
    var model_address = hub.getModelAddress(CONTROLLER_NAME);
    Assert.equal(
      ModelInterface(model_address).modelGetController(),
      0x101,
      "Initial controller address set correctly"
    );

    hub.setModelController(CONTROLLER_NAME, 0x102);
    Assert.equal(
      ModelInterface(model_address).modelGetController(),
      0x102,
      "Update of controller through hub is working"
    );

    ModelInterface(model_address).modelSetController(0x103);
    Assert.equal(
      ModelInterface(model_address).modelGetController(),
      0x103,
      "Controller is updated since current sender is an owner of the Hub"
    );

    var controllerChangingController = new ControllerChangingController();
    ModelInterface(model_address).modelSetController(controllerChangingController);
    ControllerChangingController(model_address).setNewController(model_address, 0x104);
    Assert.equal(
      ModelInterface(model_address).modelGetController(),
      0x104,
      "Controller updated through open method of current controller"
    );


    ModelInterface(model_address).modelSetController(controllerChangingController);
    controllerChangingController.constructDelegate(model_address);
    ControllerChangingController(model_address).setNewControllerPermissioned(model_address, 0x105);
    Assert.equal(
      ModelInterface(model_address).modelGetController(),
      0x105,
      "Controller updated through permissioned method"
    );

    ModelInterface(model_address).modelSetController(controllerChangingController);
    Assert.isTrue(
      model_address.call(bytes4(keccak256("setNewControllerPermissioned(address,address)")), bytes32(model_address), bytes32(0x106)),
      "CALL to setNewControllerPermissioned is successful"
    );
    Assert.equal(
      ModelInterface(model_address).modelGetController(),
      0x106,
      "Controller update through low-level call to permissioned method"
    );

    ModelInterface(model_address).modelSetController(controllerChangingController);
    var proxy = new ProxyAccount(model_address);
    proxy.call(bytes4(keccak256("setNewControllerPermissioned(address,address)")), bytes32(model_address), bytes32(0x107));
    Assert.equal(
      ModelInterface(model_address).modelGetController(),
      controllerChangingController,
      "Address isn't affected"
    );
  }

  function testCRD () {
    ModelFactory modelFactory = new ModelFactory();
    Assert.notEqual(modelFactory.instantiateModel(0x1), 0x0, "Empty model address");

    Hub hub = new Hub(modelFactory);
    Assert.isTrue(
      hub.call.gas(3000000)(sig("createModel(bytes32,address)"), bytes32("Cookies"), bytes32(address(0x1))),
      "Create model is successfull"
    );
    address model_address = hub.getModelAddress("Cookies");
    Assert.notEqual(model_address, 0x0, "Cookies model address is not");

    Assert.equal(ModelInterface(model_address).modelGetController(), 0x1, "Controller address is correct");

    Assert.isFalse(
      hub.call.gas(3000000)(sig("createModel(bytes32,address)"), bytes32("Cookies"), bytes32(address(0x1))),
      "Cannot create duplicate model"
    );

    Assert.equal(hub.getModelAddress("Cookies"), model_address, "Model is still the same");

    equal(
      callAndReturn(hub, toBytes(sig("getModelNames()"), 4), 96),
      hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001436f6f6b69657300000000000000000000000000000000000000000000000000",
      "getModelNames() is working"
    );

    hub.rmModel("Cookies", "Don't like");
    equal(
      callAndReturn(hub, toBytes(sig("getModelNames()"), 4), 64),
      hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000",
      "getModelNames() is working"
    );
    Assert.equal(hub.getModelAddress("Cookies"), 0, "address is empty");
    // Possible to create after deletion
    Assert.isTrue(
      hub.call.gas(3000000)(sig("createModel(bytes32,address)"), bytes32("Cookies"), bytes32(address(0x1))),
      "Create model is successfull"
    );
    Assert.notEqual(hub.getModelAddress("Cookies"), 0x0, "Cookies model address is not empty");

    // Todo: manipulate multiple models
    // Todo: Multi-model controller test
  }

  // TODO: controller logic update test
}


// Progression of different controller versions
contract DummyController is ControllerAbstract {
  uint a;
  function set (uint _a) {
    a = _a;
  }

  function get () returns (uint) {
    return a;
  }
}

contract DummyControllerLogic is DummyController {
  function set (uint _a) {
    a = _a * 3;
  }
}

contract DummyControllerNewData is DummyControllerLogic {
  uint b;
  function set (uint _a) {
    a = _a * 3;
    b = _a * 4;
  }

  function get () returns (uint) { throw; }

  function getV2 () returns (uint, uint) {
    return (a, b);
  }
}

contract DummyControllerMethod is DummyControllerNewData {
  function set (uint _a, uint _b) {
    a = _a * 3;
    b = _b;
  }
}

contract DummyControllerMethodRemoveData is DummyControllerMethod {
  // uint a; no longer in use
  function set (uint _b) {
    b = _b;
  }

  function get () returns (uint) {
    return b;
  }

  function getV2 () returns (uint, uint) { throw; }
}
