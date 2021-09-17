// Rewamped to Organization terminology from Zeppelin's repo
// Warning: additional logic is introduced
pragma solidity ^0.4.18;

import "./interfaces/ManageableInterface.sol";

// TODO: implement approval of transfer from new organization account (i.e. potency, preventing mistakes)

/**
 * @title Manageable
 * @dev The Manageable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Manageable is ManageableInterface {
  address public organization;

  struct Candidate {
    address organization;
    bytes32 reason;
  }

  Candidate public candidate;

  event NewOrganization (address organization_address, bytes32 optional_reason);

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOrg () {
    require(msg.sender == organization);
    _;
  }

  modifier eitherOrgOrCandidate () {
    require(msg.sender == organization || msg.sender == candidate.organization);
    _;
  }

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Manageable (address _organization) public {
    manageableConstructor(_organization);
  }

  // To be used in delegated contracts
  function manageableConstructor (address _organization) internal {
    if (_organization == 0) {
      _organization = msg.sender;
    }
    NewOrganization(_organization, "Initial");
    organization = _organization;
  }


  /**
   * @dev Allows the current organization to transfer control of the contract to a _new_org.
          The logic requires check of new organization's account ability to call setOrganization in the future
   * @param _new_org The address to transfer ownership to.
   * @param _optional_reason String or any other means to hint the reason for transfer.
   */
  function setOrganization (address _new_org, bytes32 _optional_reason) public eitherOrgOrCandidate {
    // Mistake prevention
    require(_new_org != address(0));

    if (candidate.organization == msg.sender) {
      // Only reason set by previous owner will be used
      NewOrganization(_new_org, candidate.reason);
      organization = _new_org;
      delete candidate;
    } else {
      candidate = Candidate(_new_org, _optional_reason);
    }
  }

  function isOrganization (address _inquiry_address) returns (bool) {
    return organization == _inquiry_address;
  }
}
