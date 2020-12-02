// SPDX-License-Identifier: GPL
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import '@openzeppelin/contracts/proxy/Initializable.sol';
import "./interfaces/ISprout.sol";

contract Sprout is ISprouts, Ownable, Initializable {
    using SafeMath for uint256;

    string name;
    uint256 totalDebt; // running tally of total owed to investors?
    uint256 totalOwed; // by the borrower to service the bond each interval -> coupons + variable payment.
    uint256 parDecimals;
    uint256 bondsNumber;
    uint256 cap;
    uint256 parValue;
    uint256 couponRate;
    uint256 term;
    uint256 timesToRedeem;
    uint256 loopLimit;
    uint256 nonce = 0;
    uint256 couponThreshold = 0;
    address oracle;
    uint256 intervalCount = 0;

    mapping(uint256 => address) bonds;
    mapping(uint256 => uint256) maturities;
    mapping(uint256 => uint256) couponsRedeemed;
    mapping(address => uint256) bondsAmount;

    uint256[] noxHistory;

    event TotalOwedUpdated(uint256 totalOwed);


    /**
    * @dev  Logic contract that proxies point to
    * @param _par Par value
    * @param _parDecimals Par decimals
    * @param _coupon Coupon
    * @param _term Term
    * @param _cap Cap
    * @param _timesToRedeem Times to redeem
    * @param _loopLimit (To limit the for cycle when issuing the bonds)
     */
    function initialize(        
        string memory _name,
        uint256 _par,
        uint256 _parDecimals,
        uint256 _coupon,
        uint256 _term,
        uint256 _cap,
        uint256 _timesToRedeem,
        uint256 _loopLimit,
        address _spatialRegistry,
        address _owner
        // address _oracle
        ) public {
        require(bytes(_name).length > 0, "Empty name provided");
        require(_coupon > 0, "Coupon rate lower than or equal 0 ");
        require(_par > 0, "Par lower than or equal 0");
        require(_term > 0, "Term lower than or equal 0");
        require(_loopLimit > 0, "Loop limit lower than or equal 0");
        require(_timesToRedeem > 0, "Times to redeem lower or equal to 0");

        name = _name;
        parValue = _par;
        cap = _cap;
        loopLimit = _loopLimit;
        parDecimals = _parDecimals;
        timesToRedeem = _timesToRedeem;
        couponRate = _coupon;
        term = _term;
        couponThreshold = term.div(timesToRedeem);
        // oracle = _oracle;
    }


    /**
     * @notice Change the number of elements you can loop through in this contract
     * @param _loopLimit The new loop limit
     */

    function changeLoopLimit(uint256 _loopLimit) public override onlyOwner {
        require(_loopLimit > 0, "Loop limit lower than or equal to 0");

        loopLimit = _loopLimit;
    }

    /**
     * @notice Issues bonds to a new buyer
     * @param buyer The buyer of the bonds
     * @param _bondsAmount How many bonds to mint
     */
    // Add payable function ()
    function issueBond(address buyer, uint256 _bondsAmount)
        public
        override
        onlyOwner
    {
        require(buyer != address(0), "Buyer can't be address null");
        require(
            _bondsAmount > 0,
            "Amount of bonds to mint must be higher than 0"
        );
        require(
            _bondsAmount <= loopLimit,
            "Amount of bonds to mint must be lower than the loop limit"
        );

        if (cap > 0) {
            require(
                bondsNumber.add(_bondsAmount) <= cap,
                "Total amount of bonds must be lower or equal to the cap"
            );
        }

        bondsNumber = bondsNumber.add(_bondsAmount);

        nonce = nonce.add(_bondsAmount);

        for (uint256 i = 0; i < _bondsAmount; i++) {
            // WARNING: we should consider switching 'now' for the 'block.number', this is insecure - João
            maturities[nonce.sub(i)] = now.add(term);
            bonds[nonce.sub(i)] = buyer;
            couponsRedeemed[nonce.sub(i)] = 0;
            bondsAmount[buyer] = bondsAmount[buyer].add(_bondsAmount);
        }

        totalDebt = totalDebt.add(parValue.mul(_bondsAmount)).add(
            (parValue.mul(couponRate).div(100)).mul(
                timesToRedeem.mul(_bondsAmount)
            )
        );

        emit BondsIssued(buyer, _bondsAmount);
    }

    /**
     * @notice Redeem coupons on your bonds
     * @param _bonds An array of bond ids corresponding to the bonds you want to redeem apon
     */
    // maybe add onlyOwner and automate off-chain
    function redeemCoupons(uint256[] memory _bonds) public override {
        require(_bonds.length > 0, "Array of bonds must not be empty");
        require(
            _bonds.length <= loopLimit,
            "Array of bonds must have a number of bonds lower than the looop limit"
        );
        require(
            _bonds.length <= getBalance(msg.sender),
            "Array of bonds must have a number of bonds lower than the balance of the bonds of the sender"
        );

        uint256 issueDate = 0;
        uint256 lastThresholdRedeemed = 0;
        uint256 toRedeem = 0;

        for (uint256 i = 0; i < _bonds.length; i++) {
            if (
                bonds[_bonds[i]] != msg.sender ||
                couponsRedeemed[_bonds[i]] == timesToRedeem
            ) continue;

            issueDate = maturities[_bonds[i]].sub(term);

            lastThresholdRedeemed = issueDate.add(
                couponsRedeemed[_bonds[i]].mul(couponThreshold)
            );

            if (
                lastThresholdRedeemed.add(couponThreshold) >=
                maturities[_bonds[i]] ||
                now < lastThresholdRedeemed.add(couponThreshold)
            ) continue;

            toRedeem = (now.sub(lastThresholdRedeemed)).div(couponThreshold);

            if (toRedeem == 0) continue;

            couponsRedeemed[_bonds[i]] = couponsRedeemed[_bonds[i]].add(
                toRedeem
            );

            getMoney(
                toRedeem.mul(
                    parValue.mul(couponRate).div(10**(parDecimals.add(2)))
                ),
                msg.sender
            );

            if (couponsRedeemed[_bonds[i]] == timesToRedeem) {
                bonds[_bonds[i]] = address(0);
                maturities[_bonds[i]] = 0;
                bondsAmount[msg.sender]--;

                getMoney(parValue.div((10**parDecimals)), msg.sender);
            }
        }

        emit RedeemedCoupons(msg.sender, _bonds);
    }

    /**
     * @notice Transfer bonds to another address
     * @param receiver The receiver of the bonds
     * @param _bonds The ids of the bonds that you want to transfer
     */

    function transfer(address receiver, uint256[] memory _bonds)
        public
        override
    {
        require(_bonds.length > 0, "Array of bonds must not be empty");
        require(receiver != address(0), "Receiver can't be address null");
        require(
            _bonds.length <= getBalance(msg.sender),
            "Array of bonds must have a number of bonds lower than the balance of the bonds of the sender"
        );

        for (uint256 i = 0; i < _bonds.length; i++) {
            if (
                bonds[_bonds[i]] != msg.sender ||
                couponsRedeemed[_bonds[i]] == timesToRedeem
            ) continue;

            bonds[_bonds[i]] = receiver;
            bondsAmount[msg.sender] = bondsAmount[msg.sender].sub(1);
            bondsAmount[receiver] = bondsAmount[receiver].add(1);
        }

        emit Transferred(msg.sender, receiver, _bonds);
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "Only the oracle is authorized to call this function.");
        _;
    }

    /**
     * @notice Update the total debt the borrower must pay to service the bond each interval
     * @param noxMeasurement The amount in wei the borrower has to pay. Calculated by the oracle
     *      from the DEFRA NOx data of London
     */

    function updateTotalOwed(uint256 noxMeasurement) public { // called every 1 year by an off-chain oracle EOA
        // example noxMeasurement: 44410000000000000000 i.e. 44.41 ether in wei. i.e. 44.41 * 10e18

        // Check to make sure that oracle update is due?
        // other checks on the input value?
        // We could have a range of possible values (from 0 to max variable payment) to reduce risks

        // Add NOx measurement to array so we have a record
        noxHistory.push(noxMeasurement);

        // Calculate penalty and add to total coupons for that year
        totalOwed += noxMeasurement.mul(2).add(bondsNumber.mul(parValue).mul(couponRate).div(100));

        emit TotalOwedUpdated(totalOwed);

    }

    function payTotalDebt() public payable onlyOwner {
        require(msg.value < totalDebt, "Transaction amount is higher than total owed");
        // add requirement that msg.value is == totalDebt
        totalDebt -= msg.value;
    }

    /**
     * @notice Donate money to this contract
     */

//    function donate() public override payable {
//        require(address(token) == address(0));
//    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice Transfer coupon money to an address
     * @param amount The amount of money to be transferred
     * @param receiver The address which will receive the money
     */

    function getMoney(uint256 amount, address payable receiver) private {
//        if (address(token) == address(0))
//            receiver.transfer(amount);
//        else
//            ERC20(token).transfer(msg.sender, amount);
        receiver.transfer(amount);
        totalDebt = totalDebt.sub(amount); // ?
    }

    //GETTERS

    /**
     * @dev Get the last time coupons for a particular bond were redeemed
     * @param bond The bond id to analyze
     */

    function getLastTimeRedeemed(uint256 bond)
        public
        override
        view
        returns (uint256)
    {
        uint256 issueDate = maturities[bond].sub(term);

        uint256 lastThresholdRedeemed = issueDate.add(
            couponsRedeemed[bond].mul(couponThreshold)
        );

        return lastThresholdRedeemed;
    }

    /**
     * @dev Get the owner of a specific bond
     * @param bond The bond id to analyze
     */

    function getBondOwner(uint256 bond) public override view returns (address) {
        return bonds[bond];
    }

    /**
     * @dev Get how many coupons remain to be redeemed for a specific bond
     * @param bond The bond id to analyze
     */

    function getRemainingCoupons(uint256 bond)
        public
        override
        view
        returns (int256)
    {
        address owner = getBondOwner(bond);

        if (owner == address(0)) return -1;

        uint256 redeemed = getCouponsRedeemed(bond);

        return int256(timesToRedeem - redeemed);
    }

    /**
     * @dev Get how many coupons were redeemed for a specific bond
     * @param bond The bond id to analyze
     */

    function getCouponsRedeemed(uint256 bond)
        public
        override
        view
        returns (uint256)
    {
        return couponsRedeemed[bond];
    }

    /**
     * @dev Get the address of the token that is redeemed for coupons
     */
//
//    function getTokenAddress() public override view returns (address) {
//        return (address(token));
//    }

    /**
     * @dev Get how many times coupons can be redeemed for bonds
     */

    function getTimesToRedeem() public override view returns (uint256) {
        return timesToRedeem;
    }

    /**
     * @dev Get how much time it takes for a bond to mature
     */

    function getTerm() public override view returns (uint256) {
        return term;
    }

    /**
     * @dev Get the maturity date for a specific bond
     * @param bond The bond id to analyze
     */

    function getMaturity(uint256 bond) public override view returns (uint256) {
        return maturities[bond];
    }

    /**
     * @dev Get how much money is redeemed on a coupon
     */

    function getSimpleInterest() public override view returns (uint256) {
        uint256 rate = getCouponRate();

        uint256 par = getParValue();

        return par.mul(rate).div(100);
    }

    /**
     * @dev Get the yield of a bond
     */

    function getCouponRate() public override view returns (uint256) {
        return couponRate;
    }

    /**
     * @dev Get the par value for these bonds
     */

    function getParValue() public override view returns (uint256) {
        return parValue;
    }

    /**
     * @dev Get the cap amount for these bonds
     */

    function getCap() public override view returns (uint256) {
        return cap;
    }

    /**
     * @dev Get amount of bonds that an address has
     * @param who The address to analyze
     */

    function getBalance(address who) public override view returns (uint256) {
        return bondsAmount[who];
    }

    /**
     * @dev If the par value is a real number, it might have decimals. Get the amount of decimals the par value has
     */

    function getParDecimals() public override view returns (uint256) {
        return parDecimals;
    }

    /**
     * @dev Get the name of this smart bond contract
     */

    function getName() public override view returns (string memory) {
        return name;
    }

    /**
     * @dev Get the current unpaid debt
     */

    function getTotalDebt() public override view returns (uint256) {
        return totalDebt;
    }

    /**
     * @dev Get total debt owed by borrower
     */
    
    function getTotalOwed() public override view returns (uint256) {
        return totalOwed;
    }

    /**
     * @dev Get the total amount of bonds issued
     */

    function getTotalBonds() public override view returns (uint256) {
        return bondsNumber;
    }

    /**
     * @dev Get the latest nonce
     */

    function getNonce() public override view returns (uint256) {
        return nonce;
    }

    /**
     * @dev Get the amount of time that needs to pass between the dates when you can redeem coupons
     */

    function getCouponThreshold() public override view returns (uint256) {
        return couponThreshold;
    }
}