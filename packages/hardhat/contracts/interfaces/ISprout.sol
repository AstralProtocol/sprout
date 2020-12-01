// SPDX-License-Identifier: GPL
pragma solidity 0.6.12;

interface ISprouts {

  event BondsIssued(address buyer, uint256 bondsAmount);

  event RedeemedCoupons(address indexed caller, uint256[] bonds);

  event ClaimedPar(address indexed caller, uint256 amountClaimed);

  event Transferred(address indexed from, address indexed to, uint256[] bonds);


  function changeLoopLimit(uint256 _loopLimit) external;

  function mintBond(address buyer, uint256 bondsAmount) external;

  function redeemCoupons(uint256[] memory _bonds ) external;

  function transfer(address receiver, uint256[] memory bonds) external;

//  function donate() external payable;


  //GETTERS

  function getBondOwner(uint256 bond) external view returns (address);

  function getRemainingCoupons(uint256 bond) external view returns (int256);

  function getLastTimeRedeemed(uint256 bond) external view returns (uint256);

  function getSimpleInterest() external view returns (uint256);

  function getCouponsRedeemed(uint256 bond) external view returns (uint256);

//  function getTokenAddress() external view returns (address);

  function getTimesToRedeem() external view returns (uint256);

  function getTerm() external view returns (uint256);

  function getMaturity(uint256 bond) external view returns (uint256);

  function getCouponRate() external view returns (uint256);

  function getParValue() external view returns (uint256);

  function getCap() external view returns (uint256);

  function getBalance(address who) external view returns (uint256);

  function getParDecimals() external view returns (uint256);

  // function getTokenToRedeem() external view returns (address);

  function getName() external view returns (string memory);

  function getTotalDebt() external view returns (uint256);

  function getTotalOwed() external view returns (uint256);

  function getTotalBonds() external view returns (uint256);

  function getNonce() external view returns (uint256);

  function getCouponThreshold() external view returns (uint256);

}