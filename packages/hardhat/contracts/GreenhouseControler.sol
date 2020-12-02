  
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import "./interfaces/IProxy.sol";
import "./interfaces/IGreenhouseController.sol";
import "./interfaces/IGreenhouseImplementation.sol";
import "./Ownable.sol";

contract GreenhouseController is Ownable, IGreenhouseController {
    address public pairLogic;
    address public currentAdmin;

    /*
    * @dev Type variable:
    * 2 - Pair
    */
    uint256 constant public PAIR_TYPE = 2;

    event NewPairLogic(address indexed logic);
    event NewAdmin(address indexed adminAddress);
    event UpdateProxy(address indexed proxyAddress, address newLogic);
    event ChangeAdmin(address indexed proxyAddress, address newAdmin);

    constructor(address _pairLogic) public {
        require(_pairLogic != address(0), "WSController: Wrong pair logic address");
        currentAdmin = address(this);
        pairLogic = _pairLogic;
    }


    function updatePairLogic(address _logic) external override onlyOwner {
        pairLogic = _logic;
        emit NewPairLogic(_logic);
    }

    function updateCurrentAdmin(address _newAdmin) external override onlyOwner {
        currentAdmin = _newAdmin;
        emit NewAdmin(_newAdmin);
    }

    function updateProxyPair(address _proxy) external override {
        require(IGreenhouseImplementation(IProxy(_proxy).implementation()).getImplementationType() == PAIR_TYPE, "WSController: Wrong pair proxy for update.");
        IWSProxy(_proxy).upgradeTo(pairLogic);
        emit UpdateProxy(_proxy, pairLogic);
    }

    function setAdminForProxy(address _proxy) external override {
        IWSProxy(_proxy).changeAdmin(currentAdmin);
        emit ChangeAdmin(_proxy, currentAdmin);
    }

    function getLogicForPair() external view override returns(address) {
        return pairLogic;
    }

    function getCurrentAdmin() external view override returns(address){
        return currentAdmin;
    }

}