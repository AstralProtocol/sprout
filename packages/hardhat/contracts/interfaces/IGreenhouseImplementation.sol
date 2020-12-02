// SPDX-License-Identifier: APACHE OR MIT
pragma solidity ^0.6.12;

interface IGreenhouseImplementation {
	function getImplementationType() external pure returns(uint256);
}