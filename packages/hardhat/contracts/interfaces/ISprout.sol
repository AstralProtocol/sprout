// SPDX-License-Identifier: APACHE OR MIT
pragma solidity 0.6.12;

interface ISprout {

  event BondsIssued(address buyer, uint256 bondsAmount);

  event BondTransferred(address indexed from, address indexed to, uint indexed bondId);
  
  event RedeemedCoupons(address indexed caller, uint256 indexed bondId);

  event ClaimedPar(address indexed caller, uint256 amountClaimed);

  event TotalOwedUpdated(uint256 totalOwed);

  function initialize(        
    address _factory,    
    string memory _name,
    uint256 _par,
    uint256 _parDecimals,
    uint256 _coupon,
    uint256 _term,
    uint256 _cap,
    uint256 _timesToRedeem,
    uint256 _loopLimit,
    address _spatialRegistry
  ) external returns(bool);

  function changeLoopLimit(uint256 _loopLimit) external;

  function issueBond(address buyer, uint256 bondsAmount) external payable;

  function redeemCoupons(uint256[] memory _bonds ) external;

  function transfer(address receiver, uint256[] memory bonds) external;


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