const { expect } = require("chai");
const { assert } = require("console");
const { ethers } = require("hardhat");

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});

// ref: https://solidity-jp.readthedocs.io/ja/latest/introduction-to-smart-contracts.html
// ref: https://hardhat.org/tutorial/testing-contracts.html
describe("Coin", function () {
  it("Should receive minted coin", async function () {
    const [owner, receiver] = await ethers.getSigners();
    const Coin = await ethers.getContractFactory("Coin");
    const coin = await Coin.deploy();
    await coin.deployed();
    await coin.mint(receiver.address, 100);
    expect(await coin.balances(receiver.address)).to.equal(100);
  });

  it("Should send coin to receiver.", async function () {
    const [owner, receiver] = await ethers.getSigners();
    const Coin = await ethers.getContractFactory("Coin");
    const coin = await Coin.deploy();
    await coin.deployed();
    await coin.mint(owner.address, 100);
    expect(await coin.balances(owner.address)).to.equal(100);
    await coin.send(receiver.address, 100);
    expect(await coin.balances(owner.address)).to.equal(0);
  });

  it("Should not be minted the overflowing amount of coin.", async function () {
    const [owner, receiver] = await ethers.getSigners();
    const Coin = await ethers.getContractFactory("Coin");
    const coin = await Coin.deploy();
    await coin.deployed();
    await expect(coin.mint(receiver.address, 1e60)).to.be.reverted;
  });

  it("Should not be withdrawed the insufficient amount of coin.", async function () {
    const [owner, receiver] = await ethers.getSigners();
    const Coin = await ethers.getContractFactory("Coin");
    const coin = await Coin.deploy();
    await coin.deployed();
    await expect(coin.send(receiver.address, 1e60)).to.be.reverted;
  });
});

describe("Ballot", function () {
  const v1 =
    "0x0000000000000000000000000000000000000000000000000000000000000061";
  const v2 =
    "0x0000000000000000000000000000000000000000000000000000000000000062";

  it("Should initialize proporsals.", async function () {
    const [owner] = await ethers.getSigners();
    const Ballot = await ethers.getContractFactory("Ballot");
    const ballot = await Ballot.deploy([v1, v2]);
    await ballot.deployed();
    expect((await ballot.getProposals()).length).to.equal(2);
  });

  describe("giveRightToVote", function () {
    it("Should give right to vote for a voter.", async function () {
      const [owner, voter] = await ethers.getSigners();
      const Ballot = await ethers.getContractFactory("Ballot");
      const ballot = await Ballot.deploy([v1, v2]);
      await ballot.deployed();
      await expect(ballot.giveRightToVote(voter.address)).not.to.be.reverted;
    });

    it("Should reverte if it's accessed except owner", async function () {
      const [owner, voter] = await ethers.getSigners();
      const Ballot = await ethers.getContractFactory("Ballot");
      const ballot = await Ballot.deploy([v1, v2]);
      await ballot.deployed();
      await expect(ballot.connect(voter).giveRightToVote(voter.address)).to.be
        .reverted;
    });

    it("Should reverte if it's alredy voted", async function () {
      const [owner, voter] = await ethers.getSigners();
      const Ballot = await ethers.getContractFactory("Ballot");
      const ballot = await Ballot.deploy([v1, v2]);
      await ballot.deployed();
      await ballot.giveRightToVote(voter.address);
      await expect(ballot.giveRightToVote(voter.address)).to.be.reverted;
    });
  });

  describe("delegate", function () {
    it("Should delegate a voter right to a new voter.", async function () {
      const [owner, from, to] = await ethers.getSigners();
      const Ballot = await ethers.getContractFactory("Ballot");
      const ballot = await Ballot.deploy([v1, v2]);
      await ballot.giveRightToVote(from.address);
      await ballot.giveRightToVote(to.address);
      await expect(ballot.connect(from).delegate(to.address)).not.to.be
        .reverted;
    });

    it("Should be invalid if sender is already voted.", async function () {
      const [owner, from, to] = await ethers.getSigners();
      const Ballot = await ethers.getContractFactory("Ballot");
      const ballot = await Ballot.deploy([v1, v2]);
      await ballot.giveRightToVote(from.address);
      await ballot.giveRightToVote(to.address);
      await ballot.connect(from).vote(0);
      await expect(ballot.connect(from).delegate(to.address)).to.be.reverted;
    });

    it("Should not permit to increase own vote right.", async function () {
      const [owner, to] = await ethers.getSigners();
      const Ballot = await ethers.getContractFactory("Ballot");
      const ballot = await Ballot.deploy([v1, v2]);
      await ballot.giveRightToVote(to.address);
      await expect(ballot.connect(to).delegate(to.address)).to.be.reverted;
    });
  });

  describe("vote", function () {
    it("Should success.", async function () {
      const [owner, voter] = await ethers.getSigners();
      const Ballot = await ethers.getContractFactory("Ballot");
      const ballot = await Ballot.deploy([v1, v2]);
      await ballot.giveRightToVote(voter.address);
      await expect(ballot.connect(voter).vote(0)).not.to.be.reverted;
    });

    it("Should be failed to double-vote.", async function () {
      const [owner, voter] = await ethers.getSigners();
      const Ballot = await ethers.getContractFactory("Ballot");
      const ballot = await Ballot.deploy([v1, v2]);
      await ballot.giveRightToVote(voter.address);
      await ballot.connect(voter).vote(0);
      await expect(ballot.connect(voter).vote(0)).to.be.reverted;
    });

    it("Should be failed to vote if voter has not right.", async function () {
      const [owner, voter, to] = await ethers.getSigners();
      const Ballot = await ethers.getContractFactory("Ballot");
      const ballot = await Ballot.deploy([v1, v2]);
      await expect(ballot.connect(voter).vote(0)).to.be.reverted;
    });
  });

  describe("winningName", function () {
    it("Should return the most voted proposal.", async function () {
      const [owner, voter] = await ethers.getSigners();
      const Ballot = await ethers.getContractFactory("Ballot");
      const ballot = await Ballot.deploy([v1, v2]);
      await ballot.connect(owner).vote(0);
      expect(await ballot.winningName()).to.equal(v1);
    });
  });
});
