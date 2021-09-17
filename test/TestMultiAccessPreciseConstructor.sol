pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "../contracts/MultiAccessPrecise.sol";
import "./Target.sol";
import "./Debug.sol";

contract TestMultiAccessPreciseConstructor is Debug {

  function testFails() {

    /*var res = address();*/
    /*Assert.equal(res, 0x0, "Should fail");*/
  }

  function testConstructor() {
    address[] memory addresses = new address[](3);
    addresses[0] = 1;
    addresses[1] = 2;
    addresses[2] = 3;
    var multi = new MultiAccessPrecise(addresses, 1, 0x0, new address[](0), 1);
    Assert.equal(multi.multiAccessIsOwner(addresses[0]), true, 'Is owner');
    Assert.equal(multi.multiAccessIsOwner(addresses[1]), true, 'Is owner');
    Assert.equal(multi.multiAccessIsOwner(addresses[2]), true, 'Is owner');
    /*- more requirement than owners
    - duplicate owners*/
    Assert.equal(multi.multiAccessRecipient(), 0x0, 'Default recepient');
    Assert.equal(multi.multiAccessRequired(),1, 'req 1');
    Assert.equal(multi.multiAccessRecipientRequired(), 1, 'rec req 1');
  }

  function testOneSimple() {
    address[] memory addresses = new address[](1);
    addresses[0] = 1;
    var multi = new MultiAccessPrecise(addresses, 1, 0x0, new address[](0), 1);
    Assert.equal(multi.multiAccessIsOwner(addresses[0]), true, 'Is owner');
    /*- more requirement than owners
    - duplicate owners*/
    Assert.equal(multi.multiAccessRecipient(), 0x0, 'Default recepient');
    Assert.equal(multi.multiAccessRequired(), 1, 'req 1');
    Assert.equal(multi.multiAccessRecipientRequired(), 1, 'rec req 1');
    Assert.equal(multi.whitelist().isWhitelisted(this), false, 'Not whitelisted');
    Assert.equal(multi.whitelist().isWhitelisted(0x0), false, 'Not whitelisted');
  }

  function testFull() {
    address[] memory addresses = new address[](3);
    addresses[0] = 1;
    addresses[1] = 2;
    addresses[2] = 3;
    address[] memory whitelisted = new address[](2);
    whitelisted[0] = this;
    whitelisted[1] = 0x23;
    var multi = new MultiAccessPrecise(addresses, 2, this, whitelisted, 2);

    Assert.equal(multi.multiAccessIsOwner(addresses[0]), true, 'Is owner');
    Assert.equal(multi.multiAccessIsOwner(addresses[1]), true, 'Is owner');
    Assert.equal(multi.multiAccessIsOwner(addresses[2]), true, 'Is owner');
    Assert.equal(multi.multiAccessRecipient(), this, 'Default recepient');
    Assert.equal(multi.multiAccessRequired(), 2, 'req 1');
    Assert.equal(multi.multiAccessRecipientRequired(), 2, 'rec req 1');
    Assert.equal(multi.whitelist().isWhitelisted(this), true, 'Whitelisted');
    Assert.equal(multi.whitelist().isWhitelisted(whitelisted[1]), true, 'Whitelisted');
  }

  // TODO, make change to failsafe
}
