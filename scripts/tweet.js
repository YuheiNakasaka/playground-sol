const ethers = require("ethers");
const CONTRACT_ADDRESS = process.env.PROXY_CONTRACT_ADDRESS;

async function tweet() {
  const provider = new ethers.providers.JsonRpcProvider(
    "http://localhost:8545"
  );
  const contract = require("../artifacts/contracts/TwitterV2.sol/TwitterV2.json");
  const abi = contract.abi;
  const twContract = new ethers.Contract(
    CONTRACT_ADDRESS,
    abi,
    provider.getSigner()
  );
  const signerOfProvider = provider.getSigner();
  const signer = twContract.connect(signerOfProvider);
  const resp = await signer.setTweetV2("Hello, World!!!!!");
  // const resp = await signer.follow("Hello, World!!!!!");
}

tweet();
