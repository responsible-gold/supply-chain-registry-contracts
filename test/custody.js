var CustodyController = artifacts.require("./HubModelController/CustodyController.sol");
var ModelFactory = artifacts.require("./HubModelController/ModelFactory.sol");
var Hub = artifacts.require("./HubModelController/Hub.sol");

contract('CustodyController', function(accounts) {
  it('should get the model address', function() {
    let custodyController, custodyModelAddress;
    return Hub.deployed()
    .then(hub => {
      return hub.getModelAddress('Custody')
      .then(address => {
        console.log('>>>>>>>>>>>>> model address', address);
        custodyModelAddress = address
      })
    })
    .then(() => {
      custodyController = CustodyController.at(custodyModelAddress);
      return Promise.resolve()
    })
    .then(() => custodyController.commitCustody.sendTransaction('0x02', '0x0'))
    .then(() => custodyController.commitCustody.sendTransaction('0x1F', '0x0'))
    .then(txHash => {
      console.log('>>>>>>>>>>>>>>> txhash for commit', txHash);
      return Promise.all([
        custodyController.isCustodyCommitted.call('0x02'),
        custodyController.isCustodyCommitted.call('0x1F'),
        custodyController.isCustodyCommitted.call('0x1A')
      ])
    })
    .then(commited => {
      console.log(commited)
      assert.equal(commited[0], true)
      assert.equal(commited[1], true)
      assert.equal(commited[2], false)
    })
  })
})