// SPDX-License-Identifier: APACHE OR MIT
pragma solidity ^0.6.12;

interface IGreenhouseController {
    function getLogicForSprout() external view returns(address);
    function getCurrentAdmin() external view returns(address);
    function updateSproutLogic(address _logic) external;
    function updateCurrentAdmin(address _newAdmin) external;
    function updateProxySprout(address _proxy) external;
    function setAdminForProxy(address _proxy) external;
}