pragma solidity ^0.6.12;

interface IGreenhouse {
    event SproutCreated(address indexed sprout);

    function sproutsLength() external view returns (uint);

    function germinate(        
        string memory _name,
        uint256 _par,
        uint256 _parDecimals,
        uint256 _coupon,
        uint256 _term,
        uint256 _cap,
        uint256 _timesToRedeem,
        uint256 _loopLimit,
        address _spatialRegistry
        ) external returns (address pair);
}