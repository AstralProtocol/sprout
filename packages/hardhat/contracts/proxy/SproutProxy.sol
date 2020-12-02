// SPDX-License-Identifier: APACHE OR MIT
pragma solidity ^0.6.12;

import './TransparentUpgradeableProxy.sol';

contract SproutProxy is TransparentUpgradeableProxy {
    constructor() public payable TransparentUpgradeableProxy() {
    }
}