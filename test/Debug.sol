pragma solidity ^0.4.2;

contract Debug {
  event DebugAddress(address _a);
  event DebugUInt(uint _i);
  event DebugBytes(bytes _b);
  event DebugBytes_8(bytes[8] _b);
  event DebugBytes32(bytes32 _b);
  event DebugString(string _s); // 8fa14613c3f39f471e474e076c08caac10bb2c40e967bd9588a29ffa851f8471
  event DebugBool(bool _b);

  //
  event LogAddress(string _desc, address _a);
  event LogUInt(string _desc, uint _i);
  event LogBytes(string _desc, bytes _b);
  event LogBytes32(string _desc, bytes32 _b);
  event LogString(string _desc, string _s);
  event LogBool(string _desc, bool _b);
}
