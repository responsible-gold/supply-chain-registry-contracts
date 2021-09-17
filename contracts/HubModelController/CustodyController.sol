pragma solidity ^0.4.18;

import "./interfaces/CustodyControllerInterface.sol";
import "./abstracts/ControllerAbstract.sol";
import "./Manageable.sol";

contract CustodyController is CustodyControllerInterface, ControllerAbstract, Manageable {
  bytes32[] public custody_hashes;
  mapping (bytes32 => bool) custody_index;
  // custody_hash => [metadata_hash]
  mapping (bytes32 => bytes32[]) public metadata_hashes;

  event CustodyCommitted (bytes32 _custody_hash);

  modifier custodyNotCommitted (bytes32 _custody_hash) {
    require(isCustodyCommitted(_custody_hash) == false);
    _;
  }

  modifier custodyCommitted (bytes32 _custody_hash) {
    require(isCustodyCommitted(_custody_hash) == true);
    _;
  }

  modifier isValidCustody (bytes32 _custody_hash) {
    require(_custody_hash != 0);
    _;
  }

  function CustodyController () public Manageable(0) {

  }

  // TODO: test well
  function delegateInit (address _model_address, string _abi, string _documentation_url) public onlyOrg {
    CustodyController(_model_address).init(msg.sender, _abi, _documentation_url);
  }

  function init (address _organization, string _abi, string _documentation_url)
    public
    onlyController
    onlyOnce(msg.sig)
  {
    super.manageableConstructor(_organization);
    super.controllerConstructor(_abi, _documentation_url);
  }

  function commitCustody (bytes32 _custody_hash)
    public
    onlyOrg
    custodyNotCommitted(_custody_hash)
    isValidCustody(_custody_hash)
    returns (bool)
  {
    CustodyCommitted(_custody_hash);

    custody_hashes.push(_custody_hash);
    custody_index[_custody_hash] = true;
  }

  function isCustodyCommitted (bytes32 _custody_hash)
    public
    constant
    returns (bool)
  {
    return custody_index[_custody_hash];
  }

  function getCustodyCommitment (bytes32 _input_custody_hash)
    public
    constant
    custodyCommitted(_input_custody_hash)
    returns (bytes32 _custody_hash)
  {
    return _input_custody_hash;
  }

  function getNumberOfCustodies () public constant returns (uint) {
    return custody_hashes.length;
  }

  function getCustodyAtIndex (uint _index)
    public
    constant
    returns (bytes32 _custody_hash)
  {
    return getCustodyCommitment(custody_hashes[_index]);
  }
}
