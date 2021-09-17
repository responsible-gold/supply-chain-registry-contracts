pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "./AssertAdv.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/HubModelController/Model.sol";
import "./Debug.sol";
import "./TypeConverter.sol";
import "./ProxyAccount.sol";
import "./Caller.sol";
import "./ReturnRawInput.sol";
import "./Thrower.sol";

contract TestModelDelegation is Debug, TypeConverter, Caller, AssertAdv {
  function testOutputLengthManipulation () {
    var controllerRawInput = new ReturnRawInput();
    var model = new Model(this, controllerRawInput);

    // No length input
    equal(
      callAndReturn(model, hex"11111111000000081122334455667788", 16),
      hex"11111111000000081122334455667788",
      "No length input should return full call data"
    );

    equal(
      callAndReturn(model, hex"00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00", 33),
      hex"00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00",
      "No length input, 32bytes+ output"
    );

    // Length input
    equal(
      callAndReturn(model, hex"ffffffff000000081122334455667788", 8),
      hex"1122334455667788",
      "Should return call data offset by 8"
    );

    // Variate output length
    equal(
      callAndReturn(model, hex"ffffffff00000006112233445566778899aabbccddeeff", 8),
      hex"1122334455660000",
      "6 bytes and zeroed after, shorter than actual output"
    );

    equal(
      callAndReturn(model, hex"ffffffff0000000a112233445566778899aabbccddeeff", 0xa + 1),
      hex"112233445566778899aa00",
      "Different variation"
    );


    // More than 32 bytes
    equal(
      callAndReturn(model, hex"ffffffff0000002200112233445566778899aabbccddeeff00112233445566778899aabbccddeeff0011", 0x22 + 1),
      hex"00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff001100",
      "Longer than 32 bytes"
    );

    /*Assert.equal(true, false, "Dummy");*/
  }

  function testMethodSignatureLength () {
    var controllerRawInput = new ReturnRawInput();
    var model = new Model(this, controllerRawInput);
    var rawInput = ReturnRawInput(model);

    // Default length change
    Assert.equal(uint(model.modelGetOutputLengthDefault()), 512, "Default setting is 512");
    model.modelSetOutputLengthDefault(5);
    Assert.equal(uint(model.modelGetOutputLengthDefault()), 5, "Has changed down to 5");
    model.modelSetOutputLengthDefault(36);
    Assert.equal(uint(model.modelGetOutputLengthDefault()), 36, "Has changed up to 36");

    model.modelSetOutputLengthDefault(4);
    equal(
      callAndReturn(model, hex"1122334411223344112233445566778899aabbccddeeff", 0x4 + 1),
      hex"1122334400",
      "Default length affecting arbitrary method"
    );

    model.modelSetOutputLengthDefault(5);
    equal(
      callAndReturn(model, hex"1122334411223344112233445566778899aabbccddeeff", 0x5 + 1),
      hex"112233441100",
      "Default length affecting arbitrary method"
    );

    model.modelSetOutputLengthDefault(33);
    equal(
      callAndReturn(model, hex"112233441122334400112233445566778899aabbccddeeff00112233445566778899", 33 + 1),
      hex"112233441122334400112233445566778899aabbccddeeff00112233445566778800",
      "Default length (32+ bytes) affecting arbitrary method"
    );

    // Method length change
    var (mr0, mr1, mr2) = rawInput.solidityReturnBytes32(0x1111111111111111111111111111111111111111111111111111111111111111, 0x2222222222222222222222222222222222222222222222222222222222222222);
    equal(mr0, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "Should stay 33 for the method");
    equal(mr1, 0xec11111122222222222222222222222222222222222222222222222222222222, "Should stay 33 for the method, only 1 bytes here, rest is input occupying same space");

    // Smaller length than default
    model.modelSetOutputLength(0xec5b4d3b, 10);

    equal(
      callAndReturn(model, hex"ec5b4d3b11111111111111111111111111111111111111111111111111111111111111112222222222222222222222222222222222222222222222222222222222222222", 11),
      hex"ffffffffffffffffffff00",
      "Length is 10, rpad by 0s"
    );

    Assert.equal(int(model.modelGetOutputLength(0xec5b4d3b)), 10, "Length change affected for the method");
    (mr0, mr1, mr2) = rawInput.solidityReturnBytes32(0x1111111111111111111111111111111111111111111111111111111111111111, 0x2222222222222222222222222222222222222222222222222222222222222222);
    equal(mr0, 0xffffffffffffffffffff11111111111111111111111111111111111111111111, "Output length affected to 10");

    // Bigger length than default
    model.modelSetOutputLength(0xec5b4d3b, 96);
    Assert.equal(int(model.modelGetOutputLength(0xec5b4d3b)), 96, "Length is now 44");
    (mr0, mr1, mr2) = rawInput.solidityReturnBytes32(0x1111111111111111111111111111111111111111111111111111111111111111, 0x2222222222222222222222222222222222222222222222222222222222222222);
    equal(mr0, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "Length is 96");
    equal(mr1, 0xec5b4d3b11111111111111111111111111111111111111111111111111111111, "Length is 96");
    equal(mr2, 0x1111111122222222222222222222222222222222222222222222222222222222, "Length is 96");

    equal(
      callAndReturn(model, hex"ec5b4d3b11111111111111111111111111111111111111111111111111111111111111112222222222222222222222222222222222222222222222222222222222222222", 97),
      hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec5b4d3b11111111111111111111111111111111111111111111111111111111111111112222222222222222222222222222222222222222222222222222222200",
      "Length is 96, padded with 0"
    );

    /*Assert.equal(true, false, "Dummy");*/
  }

  function testThrow () {
    var thrower = new Thrower();
    var model = new Model(this, thrower);

    Assert.isTrue(model.call(0xd909b403), "Executed sucessfully");
    Assert.isFalse(model.call.gas(1000000)(0x90446765), "Throwed, should return false");
    Assert.isFalse(model.call.gas(1000000)(0x0d8ab88f), "Assert, should return false");
    Assert.isFalse(model.call.gas(1000000)(0xbe17e373), "Require, should return false");
  }
}
