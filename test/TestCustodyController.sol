pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/HubModelController/Hub.sol";
import "../contracts/HubModelController/ModelFactory.sol";
import "../contracts/HubModelController/CustodyController.sol";
import "./Debug.sol";
import "./TypeConverter.sol";
import "./ProxyAccount.sol";
import "./AssertAdv.sol";
import "./Caller.sol";

contract TestCustodyController is Debug, TypeConverter, AssertAdv, Caller {

  // TODO: granular testing of components
  // - tests for Manageable
  function testGeneralScenario() public {
    var custodyController = CustodyController(getDelegatedController());

    var accountNonOwner = new ProxyAccount(custodyController);
    var custodyControllerProxied = CustodyController(accountNonOwner);

    Assert.isFalse(custodyController.isCustodyCommitted(0x01), "No custody");
    Assert.isFalse(custodyControllerProxied.isCustodyCommitted(0x01), "No custody throgh proxy");
    custodyController.commitCustody(0x01);
    Assert.isTrue(custodyControllerProxied.isCustodyCommitted(0x01), "Custody is committed now for proxy");
    Assert.isTrue(custodyController.isCustodyCommitted(0x01), "Must be committed for direct");

    custodyControllerProxied.commitCustody.gas(1000000)(0x02);
    Assert.isFalse(custodyController.isCustodyCommitted(0x02), "Not owner, cannot commit");


    custodyController.commitCustody(0x02);
    Assert.isTrue(custodyController.isCustodyCommitted(0x02), "Custody commitment must equal");
    Assert.equal(custodyController.getNumberOfCustodies(), 2, "Correct number of custodies");
  }

  function getDelegatedController () public returns (address) {
    CustodyController custodyControllerInstance = new CustodyController();

    ModelFactory modelFactory = new ModelFactory();
    Hub hub = new Hub(modelFactory);
    address model_address = hub.createModel("Custody", custodyControllerInstance);

    Assert.equal(ModelInterface(model_address).modelGetController(), custodyControllerInstance, "Controller address is incorrect");

    custodyControllerInstance.delegateInit(model_address, "{abi}", "http://docs.html");
    /*Assert.equal(CustodyController(model_address).abi(), "{abi}", "ABI set correctly");*/
    equal(
      callAndReturn(model_address, toBytes(sig("abi()"), 4), 64 + 5),
      concatBytes(hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000005",
        "{abi}"),
      "ABI set correctly"
    );

    equal(
      callAndReturn(model_address, toBytes(sig("documentation_url()"), 4), 64 + 16),
      concatBytes(hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000010",
        "http://docs.html"),
      "Docs URL set correctly"
    );
    /*Assert.equal(CustodyController(model_address).documentation_url(), "http://docs.html", "Docs set correctly");*/
    return model_address;
  }
}
