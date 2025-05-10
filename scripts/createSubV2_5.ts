// scripts/createSubV2_5.ts
import { ethers } from "hardhat";
import { Interface, LogDescription } from "ethers";

async function main() {
  const COORD_V2_5 = "0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE";
  const [deployer] = await ethers.getSigners();

  // ABI minimale con funzione ed evento
  const abi = [
    "function createSubscription() external returns (uint64)",
    "event SubscriptionCreated(uint64 indexed subId, address owner)"
  ];
  const coord = new ethers.Contract(COORD_V2_5, abi, deployer) as any;

  // 1) invoca la tx che crea la subscription
  const tx = await coord.createSubscription();
  const receipt = await tx.wait();

  // 2) parse dei log per estrarre l'evento SubscriptionCreated
  let subId: string | undefined;
  const iface = new Interface(abi);
  for (const log of receipt.logs) {
    let parsed: LogDescription | null = null;
    try {
      parsed = iface.parseLog(log);
    } catch (_e) {
      // log non matching ABI, parseLog può lanciare
    }
    if (parsed && parsed.name === "SubscriptionCreated" && parsed.args && parsed.args.subId !== undefined) {
      subId = parsed.args.subId.toString();
      break;
    }
  }

  if (!subId) {
    console.error("Errore: SubscriptionCreated event non trovato nei logs");
    process.exitCode = 1;
    return;
  }

  console.log("🎉 Created V2.5 subscription on‑chain with id:", subId);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});