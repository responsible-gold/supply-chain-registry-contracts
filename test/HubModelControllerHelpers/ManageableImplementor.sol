pragma solidity ^0.4.18;

import "../../contracts/HubModelController/Manageable.sol";


contract ManageableImplementor is Manageable {
  function ManageableImplementor (address _organization) Manageable(_organization) {

  }

  function restricted () onlyOrg {

  }

  function open () {

  }
}
