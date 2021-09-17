var CustodyController = artifacts.require("./HubModelController/CustodyController.sol");
var ModelFactory = artifacts.require("./HubModelController/ModelFactory.sol");
var Hub = artifacts.require("./HubModelController/Hub.sol");
var MultiAccess = artifacts.require("./MultiAccessPrecise.sol");

module.exports = function(deployer, network, accounts) {
  let _owners = [accounts[0], accounts[1], accounts[2], accounts[3]] /* var of type address[] here */ ;
  let _internalRequirement = 2 /* var of type uint256 here */ ;
  let _destinationRequirement = 1 /* var of type uint256 here */ ;

  // Deploy CustodyController and ModelFactory
  let multiAccess1, multiAccess2, modelAddress;
  deployer.deploy(CustodyController)
  .then(() => deployer.deploy(ModelFactory))
  // Deploy Hub with ModelFactory's address
  .then(() => deployer.deploy(Hub, ModelFactory.address))
  // Deploy MultiAccess 1 and link to Hub
  .then(() => MultiAccess.new(_owners, _internalRequirement, Hub.address, [Hub.address], _destinationRequirement))
  .then(multi1 => {
    multiAccess1 = multi1;
    console.log('>>>>>>>>>>> multi 1 address: ', multiAccess1.address)
    return Hub.deployed()
    .then(hubInstance => hubInstance.setOrganization(multiAccess1.address, '0x00'))
    .then(() => Hub.at(multi1.address))
    .then(wrapped => wrapped.setOrganization(multiAccess1.address, '0x00'))
  })
  .then(() => {
    return Hub.at(multiAccess1.address)
    .then(hubInstance => hubInstance.createModel('Custody', CustodyController.address))
    .then(() => Hub.deployed())
    .then(hubInstance => hubInstance.getModelAddress('Custody'))
    .then(address => modelAddress = address)
  })
  // Deploy MultiAccess 2 and link to Custody Controller
  .then(() => MultiAccess.new(_owners, _internalRequirement, CustodyController.address, [CustodyController.address], _destinationRequirement))
  .then(multi2 => {
    multiAccess2 = multi2;
    console.log('>>>>>>>>>>> multi 2 address: ', multi2.address)
    return CustodyController.deployed().then(res => res.contract)
    .then(controller => {
      return controller.setOrganization(multi2.address, '0x00', {from: web3.eth.coinbase})
    })
    .then(() => CustodyController.at(multi2.address)).then(res => res.contract)
    .then(wrapped => wrapped.setOrganization(multi2.address, '0x00', {from: web3.eth.coinbase, gas: 500000}))
  })
  // Link CustodyController Instance with Custody Model Instance
  .then(() => {
    console.log('>>>>>>>>>>>>>>>>> Custody Model Instance Address', modelAddress)
    return CustodyController.at(multiAccess2.address).then(res => res.contract)
    .then(controller => controller.delegateInit(modelAddress, '0x00', '0x00', {from: web3.eth.coinbase, gas: 500000}))
    .then(() => CustodyController.at(multiAccess2.address).then(res => res.contract))
    .then(controller => controller.commitCustody('0x1FFF', {from: web3.eth.coinbase, gas: 500000}))
    .then(() => CustodyController.deployed()).then(res => res.contract)
    .then(controller => controller.isCustodyCommitted('0x1FFF'))
    .then(res => console.log('>>>>>>>>>>>>>>> custody committed: ', res))
  })
};

/**
 * Deploy custody controller and model factory
 * Deploy hub with controller's address
 * deploy MultiAccess 1 with destination to Hub
 * Set Hub's org to MultiAccess 1
 * deploy MultiAccess 2 with destination to CustodyController
 * Set CustodyController's org to MultiAccess 1
 */
