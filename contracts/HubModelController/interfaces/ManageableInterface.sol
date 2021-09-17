pragma solidity ^0.4.18;

interface ManageableInterface {
  modifier onlyOrg {_;}
  modifier eitherOrgOrCandidate {_;}

  event NewOrganization (address org_address, bytes32 optional_reason);
  function setOrganization (address _address, bytes32 _optional_reason) public eitherOrgOrCandidate();
  function isOrganization (address _inquiry_address) returns (bool);
}
