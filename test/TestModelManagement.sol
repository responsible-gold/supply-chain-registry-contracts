pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "./AssertAdv.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/HubModelController/Model.sol";
import "../contracts/HubModelController/Manageable.sol";
import "./Debug.sol";
import "./TypeConverter.sol";
import "./ProxyAccount.sol";
import "./Caller.sol";
import "./Thrower.sol";

contract TestModelManagement is Debug, TypeConverter, Caller, AssertAdv {
  function testLengthChange () {
    // Testing ModelManagement through Model, to ensure proper inheritance
    ModelManagement modelManagement = new Model(this, 0x1);

    Assert.equal(uint(modelManagement.modelGetOutputLengthDefault()), 512, "Def length is 512");
    modelManagement.modelSetOutputLengthDefault(1024);
    Assert.equal(uint(modelManagement.modelGetOutputLengthDefault()), 1024, "Updated to 1024");

    modelManagement.modelSetOutputLength(0x11111111, 33);
    modelManagement.modelSetOutputLength(sig("methodName(bytes32)"), 64);

    Assert.equal(uint(modelManagement.modelGetOutputLength(0x11111111)), 33, "Updated to 33");
    Assert.equal(
      uint(modelManagement.modelGetOutputLength(sig("methodName(bytes32)"))),
      64,
      "methodName(bytes32) output length is 64"
    );
  }

  function testOwnership () {
    // Testing ModelManagement through Model, to ensure proper inheritance

    var accountA = new NonOrgProxyAccount(0);
    var controller = new ControllerChangingLength();
    ModelManagement modelManagement = new Model(accountA, controller);
    accountA.setDestination(modelManagement);
    var accountB = new NonOrgProxyAccount(modelManagement);

    Assert.isTrue(
        accountA.executeAndResult(sig("modelSetOutputLength(bytes4,uint32)"), bytes32(bytes4(0x11111111)), bytes32(15)),
        "Hub can change number output length"
    );
    Assert.equal(uint(modelManagement.modelGetOutputLength(0x11111111)), 15, "Updated to 15");

    Assert.isFalse(
        accountB.executeAndResult(sig("modelSetOutputLength(bytes4,uint32)"), bytes32(bytes4(0x11111111)), bytes32(728)),
        "Non-hub cannot change number output length"
    );
    Assert.equal(uint(modelManagement.modelGetOutputLength(0x11111111)), 15, "Isn't updated to 728");

    ControllerChangingLength(modelManagement).setOutputLength(0x11111111, 92);
    Assert.equal(
      uint(modelManagement.modelGetOutputLength(0x11111111)),
      92,
      "Delegated controller has updated the model"
    );
  }

  /*function testMultisignatureOwner () {

  }*/

  // Controller update is tested in TestHubModelBasic
}


contract NonOrgProxyAccount is ProxyAccount, Manageable {
  function NonOrgProxyAccount(address _destination) ProxyAccount(_destination) Manageable(0) {

  }
}

contract ControllerChangingLength {
  function setOutputLength(bytes4 _sig, uint32 _length) {
    ModelManagement(this).modelSetOutputLength(_sig, _length);
  }
}
