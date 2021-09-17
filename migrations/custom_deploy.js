const modelFactory = require('../build/contracts/ModelFactory.json')
const modelFactoryABI = modelFactory.abi
const modelFactoryBytecode = modelFactory.bytecode

const custodyController = require('../build/contracts/CustodyController.json')
const custodyControllerABI = custodyController.abi
const custodyControllerBytecode = custodyController.bytecode

const hub = require('../build/contracts/Hub.json')
const hubABI = hub.abi
const hubBytecode = hub.bytecode

const multiAccess = require('../build/contracts/MultiAccessPrecise.json')
const multiAccessABI = multiAccess.abi
const multiAccessBytecode = multiAccess.bytecode

const Eth = require('ethjs')
const SignerProvider = require('ethjs-provider-signer');
const sign = require('ethjs-signer').sign;
// Modify the rpc address here!
const provider = new SignerProvider('http://localhost:8545', {
  // Make sure the account associated with your private key has enough gas!
  signTransaction: (rawTx, cb) => cb(null, sign(rawTx, '0x...your private key here...'))
})
const eth = new Eth(provider)
const wallet = require("ethereumjs-wallet");
const crypto = require('crypto')

function delay(ms){
  var ctr, rej, p = new Promise(function (resolve, reject) {
    ctr = setTimeout(resolve, ms);
    rej = reject;
  });
  p.cancel = function(){ clearTimeout(ctr); rej(Error("Cancelled"))};
  return p;
}

async function deployContract(name, ABI, bytecode, txOptions, params) {
  const txHash = await eth.contract(ABI, bytecode, txOptions).new(...params)
  console.log(txHash)
  await delay(period)
  const receipt = await eth.getTransactionReceipt(txHash)
  const contractAddress = receipt.contractAddress
  const deployedCode = await eth.getCode(contractAddress)
  console.log(`>>>>>>>>>>> Is ${name} deployed? `, deployedCode.length > 3)
  console.log(`>>>>>>>>>>> ${name} address: `, contractAddress)
  return contractAddress
}

const privateKeyToAddress = function(privateKey) {
  var key = wallet.fromPrivateKey(new Buffer(privateKey, 'hex'));
  return key.getAddressString();
}

const generatePrivateKey = function() {
  // Todo: verify if generated number is correct private key.
	var n = Buffer('FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551', 'hex');
	var key = null;
	var tries = 0;
	do {
  	key = crypto.randomBytes(32);
		tries++;
	} while(key.compare(n) !== -1)
	console.log('Tries:', tries);
	return key.toString('hex');
}

const period = 20000
const _internalRequirement = 2 /* var of type uint256 here */ ;
const _destinationRequirement = 1 /* var of type uint256 here */ ;

async function steps() {
  try {
    // Modify accounts and txOptions to fit your deployment
    const accounts = await eth.accounts()
    console.log('accounts: ', accounts)
    const defaultAccount = '0x754c50465885f1ed1fa1a55b95ee8ecf3f1f4324'
    const txOptions = {from: defaultAccount, gas: 4700000}

    // Deploy ModelFactory, CustodyController, and Hub
    const modelFactoryAddress = await deployContract('modelFactory', modelFactoryABI, modelFactoryBytecode, txOptions, [])
    const custodyControllerAddress = await deployContract('custodyController', custodyControllerABI, custodyControllerBytecode, txOptions, [])
    const hubAddress = await deployContract('hub', hubABI, hubBytecode, txOptions, [modelFactoryAddress])

    // Deploy MultiAccess1, Create Custody Model, and link to Hub
    const multiAccessAddress1 = await deployContract('MultiAccess 1', multiAccessABI, multiAccessBytecode, txOptions, [accounts, _internalRequirement, hubAddress, [hubAddress], _destinationRequirement])
    const hub = await eth.contract(hubABI).at(hubAddress)
    console.log(await hub.setOrganization(multiAccessAddress1, '0x00', txOptions))
    await delay(period)
    const wrapped = await eth.contract(hubABI).at(multiAccessAddress1)
    console.log(await wrapped.setOrganization(multiAccessAddress1, '0x00', txOptions))
    await delay(period)
    console.log('>>>>> hub organization now', await hub.organization())
    const custodyHex = Eth.fromAscii('Custody')
    console.log(await wrapped.createModel(custodyHex, custodyControllerAddress, txOptions))
    await delay(period)
    const modelAddress = await hub.getModelAddress(custodyHex)

    // Deploy MultiAccess2 and link to CustodyController
    const multiAccessAddress2 = await deployContract('MultiAccess 2', multiAccessABI, multiAccessBytecode, txOptions, [accounts, _internalRequirement, custodyControllerAddress, [custodyControllerAddress], _destinationRequirement])
    const custodyController = await eth.contract(custodyControllerABI).at(custodyControllerAddress)
    console.log(await custodyController.setOrganization(multiAccessAddress2, '0x00', txOptions))
    await delay(period)
    const wrapped2 = await eth.contract(custodyControllerABI).at(multiAccessAddress2)
    console.log(await wrapped2.setOrganization(multiAccessAddress2, '0x00', txOptions))
    await delay(period)
    console.log('>>>>> custodyController organization now', await custodyController.organization())

    // Try to commit a custody
    console.log(await wrapped2.delegateInit(modelAddress[0], '0x00', '0x00', txOptions))
    await delay(period)
    console.log(await wrapped2.commitCustody('0x1FFF', txOptions))
    await delay(period)
    console.log(await custodyController.isCustodyCommitted('0x1FFF'))
  } catch (e) {
    console.error(e)
  }
}

steps()
