// scripts/createSubV2_5.ts
import { ethers } from "hardhat";
import { Interface, LogDescription } from "ethers";

async function main() {
  const COORD_V2_5 = "0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE";
  const [deployer] = await ethers.getSigners();

  const abi = [
    "function createSubscription() external returns (uint64)",
    "event SubscriptionCreated(uint64 indexed subId, address owner)"
  ];
  const coord = new ethers.Contract(COORD_V2_5, abi, deployer) as any;

  const tx = await coord.createSubscription();
  const receipt = await tx.wait();

  let subId: string | undefined;
  const iface = new Interface(abi);
  for (const log of receipt.logs) {
    let parsed: LogDescription | null = null;
    try {
      parsed = iface.parseLog(log);
    } catch (_e) {
    }
    if (parsed && parsed.name === "SubscriptionCreated" && parsed.args && parsed.args.subId !== undefined) {
      subId = parsed.args.subId.toString();
      break;
    }
  }

  if (!subId) {
    console.error("Error: SubscriptionCreated event not found in logs");
    process.exitCode = 1;
    return;
  }

  console.log("🎉 Created V2.5 subscription on‑chain with id:", subId);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
