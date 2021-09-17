pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Whitelist.sol";

contract TestWhitelist {

  function testBasic() {
    Whitelist whitelist = new Whitelist(new address[](0));
    Assert.equal(whitelist.isWhitelisted(this), false, "Should not be whitelisted");

    whitelist.add(this);
    Assert.equal(whitelist.isWhitelisted(this), true, "Should be already whitelisted");

    whitelist.add(0x01);
    Assert.equal(whitelist.isWhitelisted(0x01), true, "Should be already whitelisted");

    whitelist.add(0x416959fcd412adf41b91378de2aee331bb3ef3a6);
    Assert.equal(whitelist.isWhitelisted(0x416959fcd412adf41b91378de2aee331bb3ef3a6), true, "Should be already whitelisted");

    whitelist.remove(this);
    whitelist.remove(0x01);
    Assert.equal(whitelist.isWhitelisted(this), false, "Should not be whiteliste");
    Assert.equal(whitelist.isWhitelisted(0x01), false, "Should not be whiteliste");
    Assert.equal(whitelist.isWhitelisted(0x416959fcd412adf41b91378de2aee331bb3ef3a6), true, "Should be whitelisted");

    whitelist.remove(0x416959fcd412adf41b91378de2aee331bb3ef3a6);
    // Check alltogether
    Assert.equal(whitelist.isWhitelisted(0x416959fcd412adf41b91378de2aee331bb3ef3a6), false, "Should be removed");
    Assert.equal(whitelist.isWhitelisted(0x01), false, "Should be already whitelisted");
    Assert.equal(whitelist.isWhitelisted(this), false, "Should be already whitelisted");
  }

  function testInitiatesList() {
    address[] memory _addresses = new address[](2);
    _addresses[0] = 0x0000000000000000000000000000000000000002;
    _addresses[1] = 0x00000000000000000000000000000000000000ff;
    Whitelist whitelist = new Whitelist(_addresses);

    Assert.equal(whitelist.isWhitelisted(0x0000000000000000000000000000000000000002), true, "Should be whitelisted");
    Assert.equal(whitelist.isWhitelisted(0x00000000000000000000000000000000000000ff), true, "Should be whitelisted");
    Assert.equal(whitelist.isWhitelisted(0x0000000000000000000000000000000000000011), false, "Should not be whitelisted");

    // Test weird case
    whitelist.add(0x0000000000000000000000000000000000000002);
    Assert.equal(whitelist.isWhitelisted(0x0000000000000000000000000000000000000002), true, "Should be whitelisted");

    // Is possible to add new one
    whitelist.add(0x0000000000000000000000000000000000000003);
    Assert.equal(whitelist.isWhitelisted(0x0000000000000000000000000000000000000003), true, "Should be whitelisted");

    // rm initially whitelisted
    whitelist.remove(0x0000000000000000000000000000000000000002);
    Assert.equal(whitelist.isWhitelisted(0x0000000000000000000000000000000000000002), false, "Should be removed");
  }

  function testAllowsToAddAfterRemoval () {
    address _address = 0x8ce9c013bb4448bf62a0866f9f8d0a0da67ad764;
    Whitelist whitelist = new Whitelist(new address[](0));

    whitelist.add(_address);
    Assert.equal(whitelist.isWhitelisted(_address), true, "Should be listed");

    whitelist.remove(_address);
    Assert.equal(whitelist.isWhitelisted(_address), false, "Should be removed now");

    whitelist.add(_address);
    Assert.equal(whitelist.isWhitelisted(_address), true, "Should be listed again");
  }

  function testAdversary() {
    var _addresses = new address[](1);
    _addresses[0] = this;
    Whitelist whitelist = new Whitelist(_addresses);
    var adversary = new Adversary(whitelist);

    adversary.remove(this);
    Assert.equal(whitelist.isWhitelisted(this), true, "Should not be removed");

    adversary.add(0x0000000000000000000000000000000000000001);
    Assert.equal(whitelist.isWhitelisted(0x0000000000000000000000000000000000000001), false, "Should not be added");
  }
}

contract Adversary {
  Whitelist whitelist;

  function Adversary(Whitelist _whitelist) {
      whitelist = _whitelist;
  }

  function add(address _address) {
    whitelist.add(_address);
  }

  function remove(address _address) {
    whitelist.remove(_address);
  }
}
