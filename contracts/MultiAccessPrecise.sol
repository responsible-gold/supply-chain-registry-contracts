import './Whitelist.sol';

pragma solidity ^0.4.2;
contract MultiAccessPrecise {

    /**
    * Codes:
    * 1 - tx execution on destination contract has thrown an error
    */
    event Error(uint8 errorCode);

    /**
    * Confirmation event.
    * event
    * @param owner - The owner address.
    * @param operation - The operation name.
    * @param completed - If teh operation is completed or not.
    */
    event Confirmation(address indexed owner, bytes32 indexed operation, bool completed);

    /**
    * Revoke event.
    * event
    * @param owner - The owner address.
    * @param operation - The operation name.
    */
    event Revoke(address owner, bytes32 operation);

    /**
    * Owner change event.
    * event
    * @param oldOwner - The old owner address.
    * @param newOwner - The new owner address.
    */
    event OwnerChanged(address oldOwner, address newOwner);

    /**
    * Owner addedd event.
    * event
    * @param newOwner - The new owner address.
    */
    event OwnerAdded(address newOwner);

    /**
    * Owner removed event.
    * event
    * @param oldOwner - The old owner address.
    */
    event OwnerRemoved(address oldOwner);

    /**
    * Requirement change event.
    * event
    * @param newRequirement - The uint of the new requirement.
    */
    event RequirementChanged(uint newRequirement);

    /**
    * Recipient contract requirement change event.
    * event
    * @param newRecipientRequirement - The uint of the new recipient requirement.
    */
    event RecipientRequirementChanged(uint newRecipientRequirement);

    /**
    * Recipient contract's method requirement change event.
    * event
    * @param methodSignature - Target method signature
    * @param newRecipientMethodRequirement - The uint of the recipient method requirement.
    */
    event RecipientMethodRequirementChanged(string methodSignature, uint newRecipientMethodRequirement);

    /**
    * Recipient contract's method requirement revoked event.
    * event
    * @param methodSignature - Target method signature
    */
    event RecipientMethodRequirementRevoked(string methodSignature);

    struct PendingState {
        bool[] ownersDone;
        uint yetNeeded;
        bytes32 op;
    }

    mapping(bytes32 => uint) pendingIndex;
    PendingState[] pending;

    address public multiAccessRecipient;

    uint public multiAccessRequired;
    uint public multiAccessRecipientRequired;
    mapping(bytes4 => uint) public multiAccessRecipientMethodRequired;

    mapping(address => uint) ownerIndex;
    address[] public multiAccessOwners;
    Whitelist public whitelist;



    /**
    * Allow only the owner on msg.sender to exec the function.
    * modifier
    */
    modifier onlyowner {
        if (multiAccessIsOwner(msg.sender)) {
            _;
        }
    }

    /**
    * Allow only if many owners has agreed to exec the function.
    * modifier
    */
    modifier ownersThreshold(address _to, bytes _data) {
        if (_confirmAndCheck(_to, _data)) {
            _;
        }
    }

    modifier ownersThresholdInternal() {
        if (_confirmAndCheck(address(this), msg.data)) {
            _;
        }
    }

    /**
    * Only allow if requirement is in valid range
    * modifier
    */
    modifier requirementIsValid(uint _newRequirement) {
      if (_newRequirement > 0 && _newRequirement < multiAccessOwners.length) {
        _;
      }
    }


    /**
    * Construct of MultiAccess with the msg.sender and only multiAccessOwner and multiAccessRequired as one.
    * constructor
    */
    /*function MultiAccessPrecise() {
        multiAccessOwners.length = 2;
        multiAccessOwners[1] = msg.sender;
        ownerIndex[msg.sender] = 1;
        multiAccessRequired = 1;
        multiAccessRecipientRequired = 1;
        pending.length = 1;

        whitelist = new Whitelist(new address[](0));
    }*/

    // Not yet supported for this compiler version
    function assert(bool _assertion) {
        if (!_assertion) {
            throw;
        }
    }

    // Default:   new MultiAccessPrecise([msg.sender], 1, 0x0, new address[](0), 1)
    function MultiAccessPrecise(
      address[] _owners,
      uint _internalRequirement,
      address _defaultDestination,
      address[] _whitelistedDestinations,
      uint _destinationRequirement
    ) {
      uint _i; // Reusing
      assert(_owners.length != 0);
      assert(_internalRequirement > 0);
      assert(_destinationRequirement > 0);
      assert(_internalRequirement <= _owners.length);
      assert(_destinationRequirement <= _owners.length);

      // Owners
      multiAccessOwners.length = _owners.length + 1; // Cheaper to set full length once
      for (_i = 0; _i < _owners.length; _i++) {
        assert(ownerIndex[_owners[_i]] == 0); // No duplicates
        multiAccessOwners[_i + 1] = _owners[_i];
        ownerIndex[_owners[_i]] = _i + 1;
      }

      // Requirements
      multiAccessRequired = _internalRequirement;
      multiAccessRecipientRequired = _destinationRequirement;

      // Destinations
      multiAccessRecipient = _defaultDestination;
      whitelist = new Whitelist(_whitelistedDestinations);

      pending.length = 1;
    }

    /**
    * Know if an owner has confirmed an operation.
    * public_function
    * @param _owner - The caller of the function.
    * @param _operation - The data array.
    */
    function multiAccessHasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
        uint pos = pendingIndex[_operation];
        if (pos == 0) {
            return false;
        }
        uint index = ownerIndex[_owner];
        var pendingOp = pending[pos];
        if (index >= pendingOp.ownersDone.length) {
            return false;
        }
        return pendingOp.ownersDone[index];
    }

    /**
    * Confirm an operation.
    * internalfunction
    * @param _to - tx destination address
    * @param _data - raw data to be sent for execution onto destination contract
    */
    function _confirmAndCheck(address _to, bytes _data) onlyowner() internal returns (bool) {
        bytes32 operation = sha3(_to, _data);
        uint index = ownerIndex[msg.sender];
        if (multiAccessHasConfirmed(operation, msg.sender)) {
            return false;
        }

        var pos = pendingIndex[operation];
        if (pos == 0) {
            bytes4 _methodId = bytes4(uint8(_data[0]) * 2**24 + uint8(_data[1]) * 2**16 + uint8(_data[2]) * 2**8 + uint8(_data[3]));

            pos = pending.length++;
            pending[pos].yetNeeded = _getRequirement(_to, _methodId);
            pending[pos].op = operation;
            pendingIndex[operation] = pos;
        }

        var pendingOp = pending[pos];
        if (pendingOp.yetNeeded <= 1) {
            Confirmation(msg.sender, operation, true);
            if (pos < pending.length-1) {
                PendingState last = pending[pending.length-1];
                pending[pos] = last;
                pendingIndex[last.op] = pos;
            }
            pending.length--;
            delete pendingIndex[operation];
            return true;
        } else {
            Confirmation(msg.sender, operation, false);
            pendingOp.yetNeeded--;
            if (index >= pendingOp.ownersDone.length) {
                pendingOp.ownersDone.length = index+1;
            }
            pendingOp.ownersDone[index] = true;
        }

        return false;
    }

    /**
    * Calculate number of signatures required for the provided execution
    * internalfunction
    */
    function _getRequirement(address _to, bytes4 _methodId) internal returns (uint) {
      if (_to == address(this)) { // Internal call
        return multiAccessRequired;
      }
      else if (_to != multiAccessRecipient && !whitelist.isWhitelisted(_to)) { // To unknown contract, max requirement
        return multiAccessRequired;
      }
      // Whitelisted destinations
      else if (multiAccessRecipientMethodRequired[_methodId] > 0) { // Method requirement configured
        return multiAccessRecipientMethodRequired[_methodId];
      }
      else { // Generic call to any destination method
        return multiAccessRecipientRequired;
      }
    }

    /**
    * Remove all the pending operations.
    * internalfunction
    */
    function _clearPending() internal {
        uint length = pending.length;
        // uint 0 - 1 == MAX_VAL
        // This check is cheaper than to convert to int
        if (length == 0) {
          return;
        }
        for (uint i = length - 1; i > 0; --i) {
            delete pendingIndex[pending[i].op];
            pending.length--;
        }
    }

    // Arbitrary whitelisted destination tx can be executed with custom requirement
    function whitelistDestination(address _destination)
    ownersThresholdInternal
    external {
        whitelist.add(_destination);
    }

    function revokeWhitelistedDestination(address _destination)
    ownersThresholdInternal
    external {
        whitelist.remove(_destination);
    }

    /**
    * Know if an address is an multiAccessOwner.
    * public_function
    * @param _addr - The operation name.
    */
    function multiAccessIsOwner(address _addr) constant returns (bool) {
        return ownerIndex[_addr] > 0;
    }

    /**
    * Revoke a vote from an operation.
    * public_function
    * @param _operation -The operation name.
    */
    function multiAccessRevoke(bytes32 _operation) onlyowner() external {
        uint index = ownerIndex[msg.sender];
        if (!multiAccessHasConfirmed(_operation, msg.sender)) {
            return;
        }
        var pendingOp = pending[pendingIndex[_operation]];
        pendingOp.ownersDone[index] = false;
        pendingOp.yetNeeded++;
        Revoke(msg.sender, _operation);
    }

    /**
    * Change the address of one owner.
    * external_function
    * @param _from - The old address.
    * @param _to - The new address.
    */
    function multiAccessChangeOwner(address _from, address _to) ownersThresholdInternal external {
        if (multiAccessIsOwner(_to)) {
            return;
        }
        uint index = ownerIndex[_from];
        if (index == 0) {
            return;
        }

        _clearPending();
        multiAccessOwners[index] = _to;
        delete ownerIndex[_from];
        ownerIndex[_to] = index;
        OwnerChanged(_from, _to);
    }

    /**
    * Add a owner.
    * external_function
    * @param _owner - The address to add.
    */
    function multiAccessAddOwner(address _owner) ownersThresholdInternal external {
        if (multiAccessIsOwner(_owner)) {
            return;
        }
        uint pos = multiAccessOwners.length++;
        multiAccessOwners[pos] = _owner;
        ownerIndex[_owner] = pos;
        OwnerAdded(_owner);
    }

    /**
    * Remove a owner.
    * external_function
    * @param _owner - The address to remove.
    */
    function multiAccessRemoveOwner(address _owner) ownersThresholdInternal external {
        uint index = ownerIndex[_owner];
        if (index == 0) {
            return;
        }
        if (multiAccessRequired >= multiAccessOwners.length-1) {
            return;
        }
        if (index < multiAccessOwners.length-1) {
            address last = multiAccessOwners[multiAccessOwners.length-1];
            multiAccessOwners[index] = last;
            ownerIndex[last] = index;
        }
        multiAccessOwners.length--;
        delete ownerIndex[_owner];
        _clearPending();
        OwnerRemoved(_owner);
    }

    /**
    * Change the requirement.
    * external_function
    * @param _newRequired - The new amount of required signatures.
    */
    function multiAccessChangeRequirement(uint _newRequired)
      ownersThresholdInternal
      requirementIsValid(_newRequired)
      external
    {
        multiAccessRequired = _newRequired;
        _clearPending();
        RequirementChanged(_newRequired);
    }

    /**
    * Change the recipient requirement.
    * external_function
    * @param _newRecipientRequired - The new amount of recipient required signatures.
    */
    function multiAccessChangeRecipientRequirement(uint _newRecipientRequired)
      ownersThresholdInternal
      requirementIsValid(_newRecipientRequired)
      external
    {
        multiAccessRecipientRequired = _newRecipientRequired;
        _clearPending();
        RecipientRequirementChanged(_newRecipientRequired);
    }

    /**
    * Change the recipient method requirement.
    * external_function
    * @param _methodSignature - Signature of the target method. E.g.: doSomething(bytes4,uint32)
    *   Use explicit data types. For ex. instead of uint use uint256
    * @param _newRecipientMethodRequired - The new amount of recipient method required signatures.
    */
    function multiAccessChangeRecipientMethodRequirement(string _methodSignature, uint _newRecipientMethodRequired)
      ownersThresholdInternal
      requirementIsValid(_newRecipientMethodRequired)
      external
    {
        var _methodId = bytes4(sha3(_methodSignature));
        multiAccessRecipientMethodRequired[_methodId] = _newRecipientMethodRequired;
        _clearPending();
        RecipientMethodRequirementChanged(_methodSignature, _newRecipientMethodRequired);
    }

    /**
    * Revoke the recipient method requirement.
    * external_function
    * @param _methodSignature - Signature of the target method. E.g.: doSomething(bytes4,uint32)
    *   Use explicit data types. For ex. instead of uint use uint256
    */
    function multiAccessRevokeRecipientMethodRequirement(string _methodSignature)
      ownersThresholdInternal
      external
    {
        var _methodId = bytes4(sha3(_methodSignature));
        // Requirement not exists
        if (multiAccessRecipientMethodRequired[_methodId] == 0) {
          throw;
        }

        delete multiAccessRecipientMethodRequired[_methodId];
        _clearPending();
        RecipientMethodRequirementRevoked(_methodSignature);
    }

    /**
    * Set the recipient.
    * public_function
    * @param _address - The multiAccessRecipient address.
    */
    function multiAccessSetRecipient(address _address) ownersThresholdInternal returns (bool _success) {
        if (multiAccessRecipient == _address) {
            return true;
        }
        multiAccessRecipient = _address;
        _clearPending();
        return true;
    }

    /*
    * Call arbitrary address.
    * public_function
    * @param _to - The address to call.
    * @param _value - The value of wei to send with the call.
    * @param _data - Message data to send with the call.
    */
    /*function multiAccessCall(address _to, uint _value, bytes _data) onlymanyowners(true) returns(bool _success) {
        return _to.call.value(_value)(_data);
    }*/

    // To any address
    function execute(address _to, bytes _data) ownersThreshold(_to, _data) returns(bool _success) {
        if (_data.length > 0 ) {
            return _to.call(_data);
        }
    }

    function() ownersThreshold(multiAccessRecipient, msg.data) {
        if (msg.data.length > 0) {
            if (!multiAccessRecipient.call(msg.data)) {
                Error(1);
            }
        }
    }
}
