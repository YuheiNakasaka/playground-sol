const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Start deploy!: ", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Twitter = await ethers.getContractFactory("TwitterV1");
  console.log("Create ContractFactory!");
  const twitter = await upgrades.deployProxy(Twitter, [], {
    initializer: "initialize",
  });

  // It may take much time(about 3 hours...) to finish deployment in testnet.
  console.log("Deploying...: ", twitter.address);

  await twitter.deployed();

  console.log("Deployed!: ", twitter);
  console.log("Twitter deployed to:", twitter.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
