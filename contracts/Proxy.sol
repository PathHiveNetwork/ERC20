pragma solidity ^0.4.25;

import "./Role.sol";

contract Proxy is Role {

    event Upgraded(address indexed implementation);

    address internal _linkedContractAddress;

    function implementation() public view returns (address) {
        return _linkedContractAddress;
    }

    function upgradeTo(address newContractAddress) public administerAndAbove {
        require(newContractAddress != address(0));
        _linkedContractAddress = newContractAddress;
        emit Upgraded(newContractAddress);
    }

    function () payable public {
        address _implementation = implementation();
        require(_implementation != address(0));
        bytes memory data = msg.data;

        assembly {
            let result := delegatecall(gas, _implementation, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}
