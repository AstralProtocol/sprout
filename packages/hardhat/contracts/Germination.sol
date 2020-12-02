// SPDX-License-Identifier: APACHE OR MIT
pragma solidity 0.6.12;

import "./Soil.sol";
import "./Sprout.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
* @title Germination
* @dev Germination contract is a proxy factory, that imports the factory contract 
* @dev Intended usage: The contract allows for the instantiation of new Sprouts (Smart Green Bonds)
* contracts with given parameters.
*/
contract Germination is Soil, AccessControl {
    /***********************************|
    |             Events                |
    |__________________________________*/

    //Events when interacting with Sprouts instances
    event SproutCreated(address indexed sproutAddress); 
    
    /***********************************|
    |             Storage               |
    |__________________________________*/

    uint256 public numSprouts;
    address[] public sprouts;


    /***********************************|
    |             Functions             |
    |__________________________________*/

    constructor() Soil(type(Sprout).creationCode) public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    }


    // initializerData is the encoded call to the initializer function.
    function deploySproutContract(bytes memory initializerData) public returns (address)   {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have a DEFAULT_ADMIN_ROLE role to germinate");

        address sprout = deploy(factory, _msgSender(), initializerData);
        emit SproutCreated(sprout);
        sprouts.push(sprout);
        numSprouts += 1;
    }
}