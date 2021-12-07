const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Start deploy!: ", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  const Twitter = await hre.ethers.getContractFactory("Twitter");
  console.log("Create ContractFactory!");
  const twitter = await Twitter.deploy();
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
