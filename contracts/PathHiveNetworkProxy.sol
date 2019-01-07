pragma solidity ^0.4.25;

import "./Proxy.sol";

contract PathHiveNetworkProxy is Proxy {
    string public name = "PathHive Network";
    string public symbol = "PHV";
    uint8 public decimals = 18;

    constructor() public {}
}
