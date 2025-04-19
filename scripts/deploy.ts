import { ethers } from "hardhat";
import * as dotenv from "dotenv";
dotenv.config();

async function main() {
  const subscriptionId = BigInt(process.env.VRF_SUBSCRIPTION_ID!); // RIMOSSO .toString()

  const nftContractFactory = await ethers.getContractFactory("NFTcontract");
  const nftContract = await nftContractFactory.deploy(
    "Il Mio Fantastico NFT", // nome del tuo NFT
    "MNFT", // simbolo del tuo NFT
    subscriptionId
  );

  await nftContract.waitForDeployment();

  const contractAddress = await nftContract.getAddress();
  console.log("NFTContract deployed to:", contractAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
