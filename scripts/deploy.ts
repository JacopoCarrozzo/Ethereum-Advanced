import { ethers } from "hardhat";
import * as dotenv from "dotenv";
dotenv.config();

async function main() {
  // Legge il subscriptionId (es. 5) da .env
  const subscriptionId: bigint = BigInt(process.env.VRF_SUBSCRIPTION_ID!);

  const initialMintingCost: bigint = ethers.parseEther("0.01");
  const initialMaxSupply: number = 100;

  // Parametri VRF V2.5
  const VRF_COORDINATOR = "0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE";
  const KEY_HASH = "0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71";
  const CALLBACK_GAS_LIMIT = 900_000;
  const NUM_WORDS = 1;

  // Deploy del contratto NFT con il nuovo constructor
  const nftFactory = await ethers.getContractFactory("NFTcontract");
  const nftContract = await nftFactory.deploy(
    VRF_COORDINATOR,
    KEY_HASH,
    CALLBACK_GAS_LIMIT,
    NUM_WORDS,
    "Il Mio Fantastico NFT",
    "MNFT",
    subscriptionId,
    initialMintingCost,
    initialMaxSupply
  );
  await nftContract.waitForDeployment();
  console.log("NFTContract deployed to:", nftContract.target);

  // Aggiunge il contratto come consumer al VRF V2.5 Coordinator
  const [deployer] = await ethers.getSigners();
  const coordAbi = ["function addConsumer(uint64 subId, address consumer) external"];
  const coordinator = new ethers.Contract(VRF_COORDINATOR, coordAbi, deployer) as any;

  const tx = await coordinator.addConsumer(subscriptionId, nftContract.target);
  await tx.wait();
  console.log(`Added consumer ${nftContract.target} to subscription ${subscriptionId}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
