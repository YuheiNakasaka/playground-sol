const { ethers, upgrades } = require("hardhat");
const OLD_CONTRACT_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Start deploy!: ", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Twitter = await ethers.getContractFactory("TwitterV4");
  console.log("Create ContractFactory!");
  const twitter = await upgrades.upgradeProxy(OLD_CONTRACT_ADDRESS, Twitter);

  // It may take much time(about 3 hours...) to finish deployment in testnet.
  console.log("Deploying...: ", twitter.address);

  await twitter.deployed();

  console.log("Twitter deployed to:", twitter.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
