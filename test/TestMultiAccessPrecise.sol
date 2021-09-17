pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/MultiAccessPrecise.sol";
import "./Target.sol";
import "./Debug.sol";
import "./TypeConverter.sol";

contract TestMultiAccessPrecise is Debug, TypeConverter {

  function testBasic() {
    var ownerA = new Owner(0x0);
    MultiAccessPrecise mult = MultiAccessPrecise(ownerA.getDestinationAddress());
    var ownerB = new Owner(mult);
    var ownerC = new Owner(mult);
    var target = new Target(mult);

    Assert.equal(mult.multiAccessRecipient(), 0x0, "Address should be undefined");

    ownerA.setRecipient(target);
    Assert.equal(mult.multiAccessRecipient(), target, "Address should set now");

    Assert.equal(mult.multiAccessIsOwner(ownerA), true, "");
    Assert.equal(mult.multiAccessIsOwner(ownerB), false, "");
    Assert.equal(mult.multiAccessIsOwner(ownerC), false, "");
    ownerA.addOwner(ownerB);
    ownerA.addOwner(ownerC);
    Assert.equal(mult.multiAccessIsOwner(ownerB), true, "");
    Assert.equal(mult.multiAccessIsOwner(ownerC), true, "");

    Assert.equal(mult.multiAccessRequired(), 1, "");
    Assert.equal(mult.multiAccessRecipientRequired(), 1, "");

    ownerA.changeRecipientRequirement(2);
    ownerA.changeRequirement(2);
    Assert.equal(mult.multiAccessRequired(), 2, "");
    Assert.equal(mult.multiAccessRecipientRequired(), 2, "");

    Assert.equal(target.counter(), 0, "Should be zero");

    bytes4 _data = bytes4(sha3("count()"));
    ownerA.executeRaw(_data);
    Assert.equal(target.counter(), 0, "Should be zero");
    ownerA.executeRaw(_data);
    Assert.equal(target.counter(), 0, "Nothing should change");
    ownerB.executeRaw(_data);
    Assert.equal(target.counter(), 1, "Should be changed now");

    // Change recipient requirement
    ownerC.changeRecipientRequirement(1);
    Assert.equal(mult.multiAccessRecipientRequired(), 2, "Still must be 2");
    ownerB.changeRecipientRequirement(1);
    Assert.equal(mult.multiAccessRecipientRequired(), 1, "Overweighted by now");

    // Execute by one user
    ownerB.executeRaw(_data);
    Assert.equal(target.counter(), 2, "One sig sufficient now");
    ownerA.executeRaw(_data);
    Assert.equal(target.counter(), 3, "One sig sufficient for another owner");

    // Change internal requirement
    ownerC.changeRequirement(1);
    Assert.equal(mult.multiAccessRequired(), 2, "Still must be 2");
    ownerA.changeRequirement(1);
    Assert.equal(mult.multiAccessRequired(), 1, "1 now");

    ownerB.changeRequirement(3);
    Assert.equal(mult.multiAccessRequired(), 3, "Reset back to 3");

    // Assert.equal(true, false, "Show Events");
  }

  function testPrecise() {
    var ownerA = new Owner(0x0);
    MultiAccessPrecise mult = MultiAccessPrecise(ownerA.getDestinationAddress());
    var ownerB = new Owner(mult);
    var ownerC = new Owner(mult);
    var target = new Target(mult);
    ownerA.addOwner(ownerB);
    ownerA.addOwner(ownerC);

    // 2 of 3
    ownerC.setRecipient(target);
    ownerA.changeRecipientRequirement(2);
    ownerA.changeRecipientMethodRequirement("countPrecise()", 1);
    ownerB.changeRequirement(2);

    bytes4 _data = bytes4(sha3("count()"));
    ownerC.executeRaw(_data);
    Assert.equal(target.counter(), 0, "No change yet");
    ownerB.executeRaw(_data);
    Assert.equal(target.counter(), 1, "1 now");

    ownerC.executeRaw(bytes4(sha3("countPrecise()")));
    Assert.equal(target.counterPrecise(), 1, "1 sig is sufficient");
  }

  function testWhitelisted() {
    var ownerA = new Owner(0x0);
    MultiAccessPrecise mult = MultiAccessPrecise(ownerA.getDestinationAddress());
    var ownerB = new Owner(mult);
    var ownerC = new Owner(mult);
    var targetA = new Target(mult);
    var targetB = new Target(mult); // Is whitelisted and recipient
    var targetC = new Target(mult); // Not whitelisted
    ownerA.addOwner(ownerB);
    ownerA.addOwner(ownerC);

    // 3 of 3
    ownerC.setRecipient(targetB);
    Assert.equal(mult.whitelist().isWhitelisted(targetA), false, "Not yet");
    Assert.equal(mult.whitelist().isWhitelisted(targetB), false, "Not yet too");
    ownerA.whitelistDestination(targetA);
    ownerA.whitelistDestination(targetB);
    Assert.equal(mult.whitelist().isWhitelisted(targetA), true, "Whitelisted now");
    Assert.equal(mult.whitelist().isWhitelisted(targetB), true, "Whitelisted");
    // Can Remove
    ownerA.revokeWhitelistedDestination(targetA);
    ownerA.revokeWhitelistedDestination(targetB);
    Assert.equal(mult.whitelist().isWhitelisted(targetA), false, "Removed now");
    Assert.equal(mult.whitelist().isWhitelisted(targetB), false, "Removed");
    // Whitelist back
    ownerA.whitelistDestination(targetA);
    ownerA.whitelistDestination(targetB);
    ownerA.changeRecipientRequirement(2);
    ownerB.changeRequirement(3);

    bytes memory _data = toBytes(bytes4(sha3("count()")), 4);
    ownerA.execute(targetA, _data);
    ownerB.execute(targetA, _data);
    Assert.equal(targetA.counter(), 1, "counted");
    ownerC.execute(targetB, _data);
    ownerB.execute(targetB, _data);
    Assert.equal(targetB.counter(), 1, "counted");
    ownerA.execute(targetC, _data);
    ownerB.execute(targetC, _data);
    Assert.equal(targetC.counter(), 0, "Out of whitelist");
    ownerC.execute(targetC, _data);
    Assert.equal(targetC.counter(), 1, "Max sig required");

    // Change to 1 sig external
    ownerA.changeRecipientRequirement(1);
    ownerB.changeRecipientRequirement(1);
    ownerC.changeRecipientRequirement(1);
    ownerB.execute(targetB, _data);
    Assert.equal(targetB.counter(), 2, "counted");
    // Non-recipient
    ownerB.execute(targetA, _data);
    Assert.equal(targetA.counter(), 2, "A counted");

    // Revoke Whitelisted and execute, not the recipient one
    ownerA.revokeWhitelistedDestination(targetA);
    ownerB.revokeWhitelistedDestination(targetA);
    ownerC.revokeWhitelistedDestination(targetA);
    Assert.equal(mult.whitelist().isWhitelisted(targetA), false, "Should be removed from the list");
    ownerB.execute(targetA, _data);
    Assert.equal(targetA.counter(), 2, "not counted 1");
    ownerA.execute(targetA, _data);
    Assert.equal(targetA.counter(), 2, "not counted 2");
    ownerC.execute(targetA, _data);
    Assert.equal(targetA.counter(), 3, "Resolved now");
  }

  function testWhitelistedPrecise() {
    var ownerA = new Owner(0x0);
    MultiAccessPrecise mult = MultiAccessPrecise(ownerA.getDestinationAddress());
    var ownerB = new Owner(mult);
    var ownerC = new Owner(mult);
    var targetA = new Target(mult);
    var targetB = new Target(mult);
    ownerA.addOwner(ownerB);
    ownerA.addOwner(ownerC);

    // 2 of 3
    ownerA.whitelistDestination(targetA);
    ownerA.whitelistDestination(targetB);
    ownerA.changeRecipientRequirement(2);
    ownerB.changeRecipientMethodRequirement("countPrecise()", 1);
    ownerB.changeRequirement(2);

    // Particular method
    bytes memory _data = toBytes(bytes4(sha3("countPrecise()")), 4);
    ownerA.execute(targetA, _data);
    ownerC.execute(targetB, _data);
    Assert.equal(targetA.counterPrecise(), 1, "counted");
    Assert.equal(targetB.counterPrecise(), 1, "counted");

    // Any other method
    bytes memory _dataCount = toBytes(bytes4(sha3("count()")), 4);
    ownerC.execute(targetB, _dataCount);
    Assert.equal(targetB.counter(), 0, "not yet");
    ownerB.execute(targetB, _dataCount);
    Assert.equal(targetB.counter(), 1, "Overweighted");

    // Change other method to precise
    ownerB.changeRecipientMethodRequirement("count()", 1);
    ownerC.changeRecipientMethodRequirement("count()", 1);
    ownerA.execute(targetB, _dataCount);
    Assert.equal(targetB.counter(), 2, "Only one is needed now");

    ownerB.revokeRecipientMethodRequirement("countPrecise()");
    ownerA.revokeRecipientMethodRequirement("countPrecise()");
    ownerA.execute(targetA, _data);
    Assert.equal(targetA.counterPrecise(), 1, "Not yet");
    ownerB.execute(targetA, _data);
    Assert.equal(targetA.counterPrecise(), 2, "Counted now");
  }

  function testMethodWithParams() {
    var ownerA = new Owner(0x0);
    MultiAccessPrecise mult = MultiAccessPrecise(ownerA.getDestinationAddress());
    var ownerB = new Owner(mult);
    var ownerC = new Owner(mult);
    var target = new Target(mult);
    ownerA.addOwner(ownerB);
    ownerA.addOwner(ownerC);

    // 2 of 3
    ownerA.whitelistDestination(target);
    ownerA.changeRecipientRequirement(2);
    ownerB.changeRecipientMethodRequirement("setParam(bytes1)", 1);
    ownerB.changeRequirement(2);

    bytes memory methodId = toBytes(bytes4(sha3("setParam(bytes1)")), 4);
    bytes memory value = new bytes(32);
    value[0] = 0x21;

    ownerA.execute(target, concatBytes(methodId, value));
    DebugBytes32(target.param());
    Assert.equal(target.param(), value[0], "Updated to 0x21");

    // Test through fallback function
    ownerA.setRecipient(target);
    ownerB.setRecipient(target);

    value[0] = 0xbe;
    ownerA.executeRaw(concatBytes(methodId, value));
    Assert.equal(target.param(), value[0], "Updated to 0xbe");
  }

  function testAdversaryActions() {
    var ownerA = new Owner(0x0);
    MultiAccessPrecise mult = MultiAccessPrecise(ownerA.getDestinationAddress());
    var ownerB = new Owner(mult);
    var ownerC = new Owner(mult);
    var target = new Target(mult);
    ownerA.addOwner(ownerB);
    ownerA.addOwner(ownerC);
    var adversaryA = new Owner(mult);
    var adversaryB = new Owner(mult);

    // 1 of 3
    ownerC.setRecipient(target);
    // All to min requirement
    ownerA.changeRecipientRequirement(1);
    ownerA.changeRequirement(1);


    // Attack MultiAccess
    adversaryA.changeRequirement(2);
    adversaryB.changeRequirement(2);
    Assert.equal(mult.multiAccessRequired(), 1, "Shouldn't change");
    adversaryA.whitelistDestination(target);
    Assert.equal(mult.whitelist().isWhitelisted(target), false, "Shouldn't whitelist");
    Assert.equal(mult.multiAccessIsOwner(adversaryA), false, "Not an owner");
    Assert.equal(mult.multiAccessIsOwner(adversaryB), false, "Not an owner");

    adversaryA.changeOwner(ownerA, adversaryA);
    adversaryB.changeOwner(ownerB, adversaryB);
    Assert.equal(mult.multiAccessIsOwner(adversaryA), false, "Not an owner");
    Assert.equal(mult.multiAccessIsOwner(adversaryB), false, "Not an owner");

    adversaryA.setRecipient(0x0);
    Assert.equal(mult.multiAccessRecipient(), target, "No change");

    // Attack Destination
    adversaryA.executeRaw(toBytes(bytes4(sha3("count()")), 4));
    Assert.equal(target.counter(), 0, "Shoul be unchanged");
    adversaryB.executeRaw(toBytes(bytes4(sha3("count()")), 4));
    Assert.equal(target.counter(), 0, "Nope");

    // As second force
    ownerA.changeRecipientRequirement(2);
    ownerA.executeRaw(toBytes(bytes4(sha3("count()")), 4));
    adversaryA.executeRaw(toBytes(bytes4(sha3("count()")), 4));
    adversaryB.executeRaw(toBytes(bytes4(sha3("count()")), 4));
    Assert.equal(target.counter(), 0, "Not enough sig now");
    ownerB.executeRaw(toBytes(bytes4(sha3("count()")), 4));
    Assert.equal(target.counter(), 1, "Should be satisfied");
  }

  /*
    Ideas:
  - Possible to change owner
  - Not possible to finish action after owner is changed (pending is cleared)
  - Possible to remove owner
  - Not possible to remove owner if requirement will not be fulfilled
  */
}

// Independent account + proxy
contract Owner is Debug {
  MultiAccessPrecise destination;

  function Owner(address _destination) {
    if (_destination == 0x0) {
      address[] memory addresses = new address[](1);
      addresses[0] = this;
      destination = new MultiAccessPrecise(addresses, 1, 0x0, new address[](0), 1);
    }
    else {
      destination = MultiAccessPrecise(_destination);
    }
  }

  function getDestinationAddress() external returns (address) {
    return address(destination);
  }

  function setRecipient(address _recipient) {
    destination.multiAccessSetRecipient(_recipient);
  }

  function addOwner(address _owner) {
    destination.multiAccessAddOwner(_owner);
  }

  function changeOwner(address _current, address _new) {
    destination.multiAccessChangeOwner(_current, _new);
  }

  function changeRequirement(uint _r) {
    destination.multiAccessChangeRequirement(_r);
  }

  function changeRecipientRequirement(uint _r) {
    destination.multiAccessChangeRecipientRequirement(_r);
  }

  function changeRecipientMethodRequirement(string _methodSignature, uint _r) {
    destination.multiAccessChangeRecipientMethodRequirement(_methodSignature, _r);
  }

  function revokeRecipientMethodRequirement(string _methodSignature) {
    destination.multiAccessRevokeRecipientMethodRequirement(_methodSignature);
  }

  function whitelistDestination(address _a) {
    destination.whitelistDestination(_a);
  }

  function revokeWhitelistedDestination(address _a) {
    destination.revokeWhitelistedDestination(_a);
  }

  function execute(address _to, bytes _data) {
    if (!destination.execute(_to, _data)) {
      DebugString("CALL has thrown");
    }
  }

  function executeRaw(bytes32 _data) {
    if (!destination.call(_data)) {
      DebugString("CALL has thrown");
    }
  }

  function executeRaw(bytes _data) {
    if (!destination.call(_data)) {
      DebugString("CALL has thrown");
    }
  }
}
