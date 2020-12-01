// SPDX-License-Identifier: APACHE OR MIT
pragma solidity 0.6.12;

import "./Sprouts.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
* @title Germination
* @dev Germination contract that is instantiated once for the entire lifetime of the dapp
* (unless upgraded). 
* @dev Intended usage: The contract allows for the instantiation of new Sprouts (Smart Green Bonds)
* contracts with given parameters. Generating these contracts through this primary contract binds
* the created Sprout to this contract's address and only allowing transactions to occur through
* it.
*/
contract Germination is AccessControl {
    using SafeMath for uint256;

    /***********************************|
    |             Events                |
    |__________________________________*/

    //Events when interacting with Sprouts instances
    event SproutProduced(address indexed sproutAddress, address indexed creator); 
    
    /***********************************|
    |             Storage               |
    |__________________________________*/

    // key : Sprout, value : user
    mapping (address => address) public createdBy;

    address[] private sprouts;
    address payable private sproutsContract;

    /***********************************|
    |             Functions             |
    |_______________________________
    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the account that
     * deploys the contract.
     */
    constructor (address payable _sproutsContract) public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        sproutsContract = _sproutsContract;
    }

    function setSproutsContract (address payable _sproutsContract) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have a DEFAULT_ADMIN_ROLE role to change the sprouts contract");
        sproutsContract = _sproutsContract;
    }

    /**
    * @notice Creates a new sprout
    * @param _par
    * @param _parDecimals
    * @param _coupon
    * @param _term
    * @param _cap
    * @param _timesToRedeem
    * @param _loopLimit (To limit the for cycle when issuing the bonds)
     */
    function germinate (
        string memory _name,
        uint256 _par,
        uint256 _parDecimals,
        uint256 _coupon,
        uint256 _term,
        uint256 _cap,
        uint256 _timesToRedeem,
        uint256 _loopLimit,
        address _spatialRegistry,
       // address _oracle
        ) 
        public
        payable
    {
        //Creates a new Sprout Contract (with basic information)
        Sprout sprout = new Sprout(
            _name,
            _par,
            _parDecimals,
            _coupon,
            _term,
            _cap,
            _timesToRedeem,
            _loopLimit,
            _spatialRegistry
        );

        sprouts.push(address(sprout));
        createdBy[address(sprout)]= msg.sender;

        emit SproutProduced(address(listing),msg.sender);
    }

    /**
    * @dev This function gets the addresses of the sprouts created
    */
    function getListingAddresses() external view returns (address[] memory){
        return listingAddresses;
    }

    /**
    * @dev This function gets a specific listing creator
    */
    function getListingCreator(address _listing) external view returns (address){
        return createdBy[_listing];
    }
}
