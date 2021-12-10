const { ethers, upgrades } = require("hardhat");
// const OLD_CONTRACT_ADDRESS = "0x7223fF34EED050aeb29432521b084Efb8d296914";
// const OLD_CONTRACT_ADDRESS = "0x75cc4e6d4a95d3D44E8024Ea01499ca3E7895dE4";
const OLD_CONTRACT_ADDRESS = "0x60C164F4368139e588B0c5e11A9596988DCBEe3c";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Start upgrade!: ", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Twitter = await ethers.getContractFactory("TwitterV2");
  console.log("Create ContractFactory!");
  const twitter = await upgrades.upgradeProxy(OLD_CONTRACT_ADDRESS, Twitter);

  // It may take much time(about 3 hours...) to finish deployment in testnet.
  console.log("Deploying...: ", twitter.address);

  await twitter.deployed();

  console.log("Twitter upgraded to:", twitter.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
