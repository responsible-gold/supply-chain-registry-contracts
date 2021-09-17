pragma solidity ^0.4.18;


interface CustodyControllerInterface  {
  event CustodyCommitted (bytes32 _custody_hash);

  modifier onlyOrg () {_;}

  function commitCustody (bytes32 _custody_hash) public onlyOrg returns (bool);
  function isCustodyCommitted (bytes32 _custody_hash) public constant returns (bool);

  function getNumberOfCustodies () public constant returns (uint);
  function getCustodyAtIndex (uint _index) public constant returns (bytes32 _custody_hash);
}
