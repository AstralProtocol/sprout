// SPDX-License-Identifier: APACHE OR MIT
pragma solidity ^0.6.12;

import "./interfaces/IProxy.sol";
import "./interfaces/IGreenhouseController.sol";
import "./interfaces/IGreenhouseImplementation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GreenhouseController is Ownable, IGreenhouseController {
    address public sproutLogic;
    address public currentAdmin;

    /*
    * @dev Type variable:
    * 2 - SPROUT_TYPE
    */
    uint256 constant public SPROUT_TYPE = 2;

    event NewSproutLogic(address indexed logic);
    event NewAdmin(address indexed adminAddress);
    event UpdateProxy(address indexed proxyAddress, address newLogic);
    event ChangeAdmin(address indexed proxyAddress, address newAdmin);

    constructor(address _sproutLogic) public {
        require(_sproutLogic != address(0), "Greenhouse Controller: Wrong sprout logic address");
        currentAdmin = address(this);
        sproutLogic = _sproutLogic;
    }


    function updateSproutLogic(address _logic) external override onlyOwner {
        sproutLogic = _logic;
        emit NewSproutLogic(_logic);
    }

    function updateCurrentAdmin(address _newAdmin) external override onlyOwner {
        currentAdmin = _newAdmin;
        emit NewAdmin(_newAdmin);
    }

    function updateProxySprout(address _proxy) external override {
        require(IGreenhouseImplementation(IProxy(_proxy).implementation()).getImplementationType() == SPROUT_TYPE, "Greenhouse Controller: Wrong sprout proxy for update.");
        IProxy(_proxy).upgradeTo(sproutLogic);
        emit UpdateProxy(_proxy, sproutLogic);
    }

    function setAdminForProxy(address _proxy) external override {
        IProxy(_proxy).changeAdmin(currentAdmin);
        emit ChangeAdmin(_proxy, currentAdmin);
    }

    function getLogicForSprout() external view override returns(address) {
        return sproutLOgic;
    }

    function getCurrentAdmin() external view override returns(address){
        return currentAdmin;
    }

}