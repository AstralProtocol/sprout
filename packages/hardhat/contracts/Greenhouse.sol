// SPDX-License-Identifier: APACHE OR MIT
pragma solidity ^0.6.12;

import './proxy/SproutProxy.sol';
import './interfaces/IGreenhouse.sol';
import './interfaces/ISprout.sol';
import './interfaces/IGreenhouseController.sol';
import './interfaces/IGreenhouseImplementation.sol';

contract Greenhouse is IGreenhouse, IGreenhouseImplementation{

    /***********************************|
    |             Storage               |
    |__________________________________*/

    bool private initialized;
    address public controller;
    uint256 public numSprouts;
    address[] public sprouts;

    /***********************************|
    |             Events                |
    |__________________________________*/

    //Events when interacting with Sprouts instances
    event SproutCreated(address indexed sproutAddress); 

    /***********************************|
    |             Functions             |
    |__________________________________*/

    function initialize(address _controller) public returns(bool) {
        require(initialized == false, "Greenhouse: factory was already initialized.");
        require(_controller != address(0), "Greenhouse: controller should not bo zero address.");
        controller = _controller;
        initialized = true;
        return true;
    }

    function sproutsLength() external override view returns (uint) {
        return sprouts.length;
    }

    /**
    * @notice Creates a new sprout
    * @param _par Par value - the face value of a bond
    * @param _parDecimals Par decimals
    * @param _coupon Coupon = yield paid by a fixed-income security
    * @param _term Term - bonds mature on a specific date in the future and the bond face value must be repaid to the bondholder on that date. Uint256 timestamp of the future date
    * @param _cap Cap - Number of bonds that can be minted
    * @param _timesToRedeem Times to redeem the coupon within the term
    * @param _loopLimit (To limit the for cycle when issuing the bonds)
     */
    function germinate
    (
        string memory _name,
        uint256 _par,
        uint256 _parDecimals,
        uint256 _coupon,
        uint256 _term,
        uint256 _cap,
        uint256 _timesToRedeem,
        uint256 _loopLimit,
        address _spatialRegistry
       // address _oracle
    )
        external override returns (address sprout) {
        require(bytes(_name).length > 0, "Greenhouse: empty name provided");
        require(_coupon > 0, "Greenhouse: coupon rate lower than or equal 0 ");
        require(_par > 0, "Greenhouse: par lower than or equal 0");
        require(_term > 0, "Greenhouse: term lower than or equal 0");
        require(_loopLimit > 0, "Greenhouse: loop limit lower than or equal 0");
        require(_timesToRedeem > 0, "Greenhouse: times to redeem lower or equal to 0");

        bytes memory bytecode = type(SproutProxy).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_name, _par, _parDecimals, _coupon, _term, _cap, _timesToRedeem));
        assembly {
            sprout := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // Greenhouse as current sprout admin initializes proxy with logic and right admin
        IProxy(sprout).initialize(IGreenhouseController(controller).getLogicForSprout(), IGreenhouseController(controller).getCurrentAdmin(), "");
        // Greehouse initialized sprout with variables
        require(ISprout(sprout).initialize(address(this), _name, _par, _parDecimals, _coupon, _term, _cap, _timesToRedeem, _loopLimit, _spatialRegistry) == true, "Greenhouse: Sprout initialize did not succeed.");
        
        sprouts.push(sprout);
        emit SproutCreated(sprout);
    }

    function issueBond(address sprout, address buyer, uint256 bondsAmount) external override payable {
        ISprout(sprout).issueBond.value(msg.value)(buyer, bondsAmount);
    }


    function getImplementationType() external pure override returns(uint256) {
        /// 1 is a factory type
        return 1;
    }
    
}