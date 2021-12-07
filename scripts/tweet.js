const ethers = require("ethers");
const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

async function tweet() {
  const provider = new ethers.providers.JsonRpcProvider(
    "http://localhost:8545"
  );
  const contract = require("../artifacts/contracts/Twitter.sol/Twitter.json");
  const abi = contract.abi;
  const twContract = new ethers.Contract(
    CONTRACT_ADDRESS,
    abi,
    provider.getSigner()
  );
  const signerOfProvider = provider.getSigner();
  const signer = twContract.connect(signerOfProvider);
  const resp = await signer.setTweet("Hello, World!!!!!");
  // const resp = await signer.follow("Hello, World!!!!!");
}

tweet();
