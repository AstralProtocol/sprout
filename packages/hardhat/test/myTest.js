const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const { times, add, divide } = require("ramda");
const fs = require("fs");
const chalk = require("chalk");

use(solidity);

describe("Sprout dApp", function () {
  let greenhouseLogic;
  let sproutLogic;
  let greenhouseController;
  let greenhouseProxy;
  let greenhouse;
  let sprout1;

  let wallet = ethers.Wallet.fromMnemonic(fs.readFileSync("./mnemonic.txt").toString().trim())
  wallet = wallet.connect(ethers.provider)

  describe("Greenhouse", function () {
    it("Should initialize dApp", async function () {
      const accounts = await ethers.getSigners();

      console.log(`Admin account: ${accounts[0].address}`)

      const GreenhouseLogic = await ethers.getContractFactory("Greenhouse");
      greenhouseLogic = await GreenhouseLogic.deploy()

      console.log(`Greenhouse logic: ${greenhouseLogic.address}`)

      const SproutLogic = await ethers.getContractFactory("Sprout");
      sproutLogic = await SproutLogic.deploy();

      console.log(`Sprout logic: ${sproutLogic.address}`)


      const GreenhouseController = await ethers.getContractFactory("GreenhouseController");
      greenhouseController = await GreenhouseController.deploy(sproutLogic.address);
     
      console.log(`Greenhouse Controller logic: ${greenhouseController.address}`)

      
      const GreenhouseProxy = await ethers.getContractFactory("GreenhouseProxy");
      greenhouseProxy = await GreenhouseProxy.deploy();
      await greenhouseProxy.initialize(greenhouseLogic.address, accounts[0].address, [])

      console.log(`Greenhouse proxy: ${greenhouseProxy.address}`)

      greenhouse = new ethers.Contract(greenhouseProxy.address, greenhouseLogic.interface, wallet)
      await greenhouse.initialize(greenhouseController.address)

      
      console.log(
        "Greenhouse (sprouts factory) deployed to: ",
        chalk.green(greenhouse.address),
        "\n"
      );

      expect(await greenhouseController.getLogicForSprout()).to.equal(sproutLogic.address);
      expect(await greenhouseController.owner()).to.equal(accounts[0].address);
      // The admin of all proxies should be the controller
      expect(await greenhouseController.getCurrentAdmin()).to.equal(greenhouseController.address);
      expect(await greenhouse.controller()).to.equal(greenhouseController.address);
    });

    describe("germinate()", function () {
      it("Should be able to germinate a Sprout", async function () {
        const bondName = "First bond";
        const par = "10000000000000000";
        const parDecimals = 0;
        const coupon = 3;
        const term = 100;
        const cap = 100;
        const timesToRedeem = 10;
        const loopLimit = 10;
        const spatialRegistry = "0xCa49615207f86496ea62D6e02231cE6295335E11"

        const germinateTx = await greenhouse.germinate(bondName, par, parDecimals, coupon, term, cap, timesToRedeem, loopLimit, spatialRegistry);
        
        const receipt = await germinateTx.wait(1)
        const sproutCreatedEvent = receipt.events.pop()
        const sproutAddress = sproutCreatedEvent.args[0]

        sprout1 = new ethers.Contract(sproutAddress, sproutLogic.interface, wallet)
        expect(await greenhouse.sproutsLength()).to.equal(1);
        expect(await sprout1.getName()).to.equal(bondName);
        expect(await sprout1.getParValue()).to.equal(par);
        expect(await sprout1.getParDecimals()).to.equal(parDecimals);
        expect(await sprout1.getCouponRate()).to.equal(coupon);
        expect(await sprout1.getTerm()).to.equal(term);
        expect(await sprout1.getCap()).to.equal(cap);
        expect(await sprout1.getTimesToRedeem()).to.equal(timesToRedeem);
        expect(await sprout1.getLoopLimit()).to.equal(loopLimit);

        expect(await sprout1.spatialRegistry()).to.equal(spatialRegistry);
        expect(await sprout1.factory()).to.equal(greenhouse.address);
        expect(await sprout1.getImplementationType()).to.equal(2);
        expect(await sprout1.isLocked()).to.equal(1);

      });

      it("Should be able to issue Bonds", async function () {
        const accounts = await ethers.getSigners();

        const bondsAmount = 10;
        const buyer = accounts[1].address;

        let totalDebt = await sprout1.getTotalDebt();
        const parValue = await sprout1.getParValue();
        const couponRate = await sprout1.getCouponRate();
        const timesToRedeem = await sprout1.getTimesToRedeem();

        totalDebt = totalDebt.add(parValue.mul(bondsAmount)).add(
          (parValue.mul(couponRate).div(100)).mul(
              timesToRedeem.mul(bondsAmount)
          )
      );

      let overrides = {
        // To convert Ether to Wei:
        value: totalDebt.toString()     // ether in this case MUST be a string
    
        // Or you can use Wei directly if you have that:
        // value: someBigNumber
        // value: 1234   // Note that using JavaScript numbers requires they are less than Number.MAX_SAFE_INTEGER
        // value: "1234567890"
        // value: "0x1234"
    
        // Or, promises are also supported:
        // value: provider.getBalance(addr)
    };
      
        console.log(totalDebt.toString())
        const issueBondsTx = await greenhouse.issueBond(sprout1.address, buyer, bondsAmount, overrides);
        
        const receipt = await issueBondsTx.wait(1)
        const bondsIssuedEvent = receipt.events.pop()
        const buyerAddress = bondsIssuedEvent.args[0]
        const bondsAmountInContract = bondsIssuedEvent.args[1]

      
        expect(buyerAddress).to.equal(buyer);
        expect(bondsAmountInContract).to.equal(bondsAmount);
      });
    });
  });
});
