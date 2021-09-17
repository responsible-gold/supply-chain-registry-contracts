pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "./Debug.sol";
import "./TypeConverter.sol";
import "./ProxyAccount.sol";
import "./HubModelControllerHelpers/ManageableImplementor.sol";
import "../contracts/MultiAccessPrecise.sol";


contract TestManageable is Debug {
  function testBasic () {
    var manageableExtAddress = new ManageableImplementor(0x123);
    Assert.isTrue(
      manageableExtAddress.isOrganization(0x123),
      "Specified address is an organization"
    );

    var manageable = new ManageableImplementor(0);
    Assert.isTrue(manageable.isOrganization(this), "Creator is an organization");
    Assert.isTrue(
      manageable.call(sig("restricted()")),
      "Organization has access to the restricted method"
    );
    var proxy = new ProxyAccount(manageable);

    Assert.isTrue(
      proxy.executeAndResult(sig("open()")),
      "External account has access to the open method"
    );

    Assert.isFalse(
      proxy.executeAndResult(sig("restricted()")),
      "External account has no access to the restricted method"
    );
  }

  function testOrganizationChange () {
    var manageable = new ManageableImplementor(0);

    var accountA = new ProxyAccount(manageable);
    var accountB = new ProxyAccount(manageable);
    var accountC = new ProxyAccount(manageable);

    Assert.isFalse(
      accountA.executeAndResult(sig("restricted()")),
      "accountA has no access to the restricted method yet"
    );

    manageable.setOrganization(accountA, "Reason A");
    Assert.isFalse(manageable.isOrganization(accountA), "Not a new org yet");
    Assert.isFalse(
      accountA.executeAndResult(sig("restricted()")),
      "still no acces for accountA"
    );

    /*accountA.executeAndResult(sig("setOrganization(address,bytes32)"), bytes32(address(accountA)), bytes32("Reason A"));*/
    Manageable(accountA).setOrganization(accountA, "Reason A1");
    Assert.isTrue(manageable.isOrganization(accountA), "Is a new org");
    Assert.isTrue(
      accountA.executeAndResult(sig("restricted()")),
      "has access now"
    );

    // Can take permission back
    // Current owner can set another account in the middle of transfer
    Manageable(accountA).setOrganization(accountC, "Reason C");
    Manageable(accountA).setOrganization(accountB, "Reason B");
    Assert.isFalse(
      accountC.executeAndResult(sig("setOrganization(address,bytes32)"), bytes32(address(accountC)), bytes32(0)),
      "Account C cannot finish transfer"
    );
    Manageable(accountB).setOrganization(accountB, "Reason B1");
    Assert.isTrue(manageable.isOrganization(accountB), "B were able to finish the transfer");


    // Can nullify permission and the successfully transfer
    Manageable(accountB).setOrganization(accountC, "Reason C");
    Manageable(accountB).setOrganization(0x1, "nullify");
    Assert.isFalse(
      accountC.executeAndResult(sig("setOrganization(address,bytes32)"), bytes32(address(accountC)), bytes32(0)),
      "Account C cannot finish transfer"
    );
    Assert.isFalse(
      accountC.executeAndResult(sig("restricted()")),
      "has access now"
    );
    Manageable(accountB).setOrganization(accountA, "Reason A");
    Manageable(accountA).setOrganization(accountA, "Reason A1");
    Assert.isTrue(
      manageable.isOrganization(accountA),
      "Able to trasfer after nullifying pervious transfer"
    );
    Assert.isTrue(
      accountA.executeAndResult(sig("restricted()")),
      "has access now"
    );
    Assert.isFalse(
      accountB.executeAndResult(sig("restricted()")),
      "has access now"
    );
    Assert.isFalse(
      accountC.executeAndResult(sig("restricted()")),
      "has access now"
    );

    // Intermediary state cannot be misused by a malicious actor. ?
  }


  function testManageableMultiSignature () public {
    var manageable = new ManageableImplementor(0);

    // Multisig A
    var accountA = new ProxyAccount(0);
    var accountB = new ProxyAccount(0);
    var accountC = new ProxyAccount(0);

    address[] memory addressesA = new address[](3);
    addressesA[0] = accountA;
    addressesA[1] = accountB;
    addressesA[2] = accountC;
    var accountMultisigA = new MultiAccessPrecise(addressesA, 2, manageable, new address[](0), 2);
    accountA.setDestination(accountMultisigA);
    accountB.setDestination(accountMultisigA);
    accountC.setDestination(accountMultisigA);

    // Multisig B
    address[] memory addressesB = new address[](3);
    addressesB[0] = new ProxyAccount(0);
    addressesB[1] = new ProxyAccount(0);
    addressesB[2] = new ProxyAccount(0);
    var accountMultisigB = new MultiAccessPrecise(addressesB, 2, manageable, new address[](0), 2);
    ProxyAccount(addressesB[0]).setDestination(accountMultisigB);
    ProxyAccount(addressesB[1]).setDestination(accountMultisigB);
    ProxyAccount(addressesB[2]).setDestination(accountMultisigB);


    // Execution
    manageable.setOrganization(accountMultisigA, "Moving to multisig");
    Manageable(accountA).setOrganization(accountMultisigA, 0);
    Assert.isFalse(
      manageable.isOrganization(accountMultisigA),
      "One more signature needed to complete"
    );
    Manageable(accountC).setOrganization(accountMultisigA, 0);
    Assert.isTrue(
      manageable.isOrganization(accountMultisigA),
      "Enough signatures, tranfer is done"
    );


    // Transfer to another multisig
    Manageable(accountB).setOrganization(accountMultisigB, "New multisig");
    Manageable(accountC).setOrganization(accountMultisigB, "New multisig");
    Manageable(addressesB[0]).setOrganization(accountMultisigB, "New multisig");
    Manageable(addressesB[1]).setOrganization(accountMultisigB, "New multisig");
    Assert.isTrue(
      manageable.isOrganization(accountMultisigB),
      "Transfered to multisig B"
    );
  }

  function sig(string _methodSignature) public returns (bytes4) {
    return bytes4(keccak256(_methodSignature));
  }
}
