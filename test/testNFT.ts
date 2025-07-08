import { expect } from "chai";
import { ethers, network } from "hardhat";
import type { NFTcontract } from "../typechain/contracts/NFTcontract";
import type { VRFCoordinatorV2Mock } from "../typechain/contracts/mocks/VRFCoordinatorV2Mock";
import { NFTcontract__factory }           from "../typechain/factories/contracts/NFTcontract__factory";
import { VRFCoordinatorV2Mock__factory } from "../typechain/factories/contracts/mocks/VRFCoordinatorV2Mock__factory";
import type { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import type { BigNumberish } from "ethers";

const SEPOLIA_COORDINATOR = process.env.COORDINATOR_ADDRESS!;
const SEPOLIA_SUBS_ID     = process.env.SUBSCRIPTION_ID!;
const SEPOLIA_KEY_HASH    = process.env.KEY_HASH!;

describe("Local tests (Hardhat Network)", function () {
  let nft: NFTcontract;
  let vrfMock: VRFCoordinatorV2Mock;
  let owner: SignerWithAddress;
  let other: SignerWithAddress;
  let subscriptionId: BigNumberish;
  const isLocal = network.name === "hardhat";

  before(async () => {
    [owner, other] = await ethers.getSigners() as SignerWithAddress[];

    if (isLocal) {
      const vrfFactory = new VRFCoordinatorV2Mock__factory(owner);
      vrfMock = await vrfFactory.deploy(
        ethers.parseEther("0.25"),
        1e9
      );
      await vrfMock.waitForDeployment();

      const tx = await vrfMock.createSubscription();
      const receipt = await tx.wait();
      subscriptionId = (await vrfMock.queryFilter(vrfMock.filters.SubscriptionCreated()))[0].args!.subId;
      await vrfMock.fundSubscription(subscriptionId, ethers.parseEther("1000"));
    }

    const nftFactory = new NFTcontract__factory(owner);
    const callbackGasLimit = isLocal ? 3_000_000 : 500_000;
    nft = await nftFactory.deploy(
      isLocal ? vrfMock.target : SEPOLIA_COORDINATOR,
      isLocal ? ethers.encodeBytes32String("0") : SEPOLIA_KEY_HASH,
      callbackGasLimit,
      1,
      "TestNFT",
      "TNFT",
      isLocal ? subscriptionId : SEPOLIA_SUBS_ID,
      ethers.parseEther("0.01"),
      5
    ) as unknown as NFTcontract;
    await nft.waitForDeployment();

    if (isLocal) {
      await vrfMock.addConsumer(subscriptionId, nft.target);
    }
  });

  it("Should revert if not enough Ether is sent for minting", async () => {
    const cost = await nft.getMintingCost();
    await expect(
      nft.requestRandomNumber({ value: cost - ethers.parseEther("0.0001") })
    ).to.be.revertedWith("Insufficient Ether Sent");
  });

  it("Should revert if max supply is reached", async () => {
    const cost = await nft.getMintingCost();
    const max = await nft.getMaxSupply();

    for (let i = 0; i < max; i++) {
      await nft.requestRandomNumber({ value: cost, gasLimit: 5_000_000 });
    }
    await expect(
      nft.requestRandomNumber({ value: cost, gasLimit: 5_000_000 })
    ).to.be.revertedWith("Maximum NFT supply reached");
  });

  it("Should allow owner to set new minting cost", async () => {
    const newCost = ethers.parseEther("0.02");
    await nft.setMintingCost(newCost);
    expect(await nft.getMintingCost()).to.equal(newCost);
  });

  it("Should prevent non-owner from setting new minting cost", async () => {
    const newCost = ethers.parseEther("0.02");
    await expect(
      nft.connect(other).setMintingCost(newCost)
    ).to.be.revertedWith("Only callable by owner");
  });

  it("Should allow owner to set new max supply", async () => {
    const newMax = 3;
    await nft.setMaxSupply(newMax);
    expect(await nft.getMaxSupply()).to.equal(BigInt(newMax));
  });

  it("Should prevent non-owner from setting new max supply", async () => {
    const newMax = 3;
    await expect(
      nft.connect(other).setMaxSupply(newMax)
    ).to.be.revertedWith("Only callable by owner");
  });

  describe("VRF Fulfillment & Metadata (mock)", () => {
    before(async () => {
      await nft.setMaxSupply(1000);
    });

    it("mints, simulates VRF, and logs gas usage for mint & fulfill", async () => {
      const cost = await nft.getMintingCost();
      const txMint = await nft.requestRandomNumber({ value: cost, gasLimit: 5_000_000 });
      const receiptMint = (await txMint.wait())!;
      console.log("Mint gas used:", receiptMint.gasUsed.toString());

      const reqLog = receiptMint.logs
        .map(l => { try { return nft.interface.parseLog(l) } catch { return null } })
        .find(e => e?.name === "RandomNumberRequested");
      const tokenId = reqLog!.args.tokenId;
      const requestId = reqLog!.args.requestId;

      const txFulfill = await vrfMock.fulfillRandomWords(requestId, nft.target, { gasLimit: 5_000_000 });
      const receiptFulfill = (await txFulfill.wait())!;
      console.log("Fulfill gas used:", receiptFulfill.gasUsed.toString());

      const rand = await nft.getRandomNumber(tokenId);
      console.log("Random number:", rand.toString());
      expect(rand).to.be.a("bigint").and.satisfy((n: bigint) => n >= 0 && n < 25);
    });

    
    it("produces valid tokenURI JSON and logs call gas usage", async () => {
  const cost = await nft.getMintingCost();
  const mintTx = await nft.requestRandomNumber({ value: cost, gasLimit: 5_000_000 });
  const mintRcpt = (await mintTx.wait())!;

  const reqEvt = mintRcpt.logs
    .map(l => { try { return nft.interface.parseLog(l) } catch { return null } })
    .find(e => e?.name === "RandomNumberRequested");
  const tid = reqEvt!.args.tokenId;
  const rid = reqEvt!.args.requestId;

  await vrfMock.fulfillRandomWords(rid, nft.target, { gasLimit: 5_000_000 });

  const [name, description, city, luckyNumber, tourChance] = await nft.getTokenMetadata(tid);
  console.log({ name, city, luckyNumber, tourChance });

  expect(name).to.match(/^City NFT #[0-9]+$/);
  expect(description).to.contain(city);
  expect(["Yes", "No"]).to.include(tourChance);
});


    it("getCityAndDescription yields correct city for 0-24 and logs each", async () => {
  const cities = [
    "Berlin", "Paris", "Rome", "Madrid", "Amsterdam", "Frankfurt", "London", "Dublin",
    "Brussels", "Zurich", "Milan", "Marseille", "Vienna", "Prague", "Barcelona",
    "Florence", "Rotterdam", "Copenhagen", "Stockholm", "Oslo", "Helsinki",
    "Reykjavik", "Naples", "Athens", "Mannheim"
  ];
  for (let i = 0; i < 25; i++) {
    const cost = await nft.getMintingCost();
    const tx = await nft.requestRandomNumber({ value: cost, gasLimit: 5_000_000 });
    const rcpt = (await tx.wait())!;
    const evt = rcpt.logs
      .map(l => { try { return nft.interface.parseLog(l) } catch { return null } })
      .find(e => e?.name === "RandomNumberRequested");
    const tid = evt!.args.tokenId;
    const rid = evt!.args.requestId;

    
    let simulatedRandomWord = i;
    if (i === 0) {
      simulatedRandomWord = 0; 
    }

    const fulfillTx = await vrfMock.fulfillRandomWordsWithOverride(rid, nft.target, [BigInt(simulatedRandomWord)], { gasLimit: 5_000_000 });
    const fulfillRcpt = await ethers.provider.getTransactionReceipt(fulfillTx.hash);
    console.log(`Iteration ${i}: fulfill gas `, fulfillRcpt!.gasUsed.toString());


    const [ description, city ] = await nft.getTokenMetadata(tid);
    console.log(`Iteration ${i}: city = ${city}`);

    expect(city).to.equal(cities[i]);
    expect(description).to.contain(cities[i]);
  }
});
  });
});

const hasSepoliaEnv = !!(
  process.env.COORDINATOR_ADDRESS &&
  process.env.SUBSCRIPTION_ID &&
  process.env.KEY_HASH
);
(hasSepoliaEnv ? describe : describe.skip)("Sepolia integration tests", function () {
  let nft: NFTcontract;
  let owner: SignerWithAddress;
  let other: SignerWithAddress;

  before(async () => {
    [owner, other] = await ethers.getSigners() as SignerWithAddress[];

    const nftFactory = new NFTcontract__factory(owner);
    nft = await nftFactory.deploy(
      SEPOLIA_COORDINATOR,
      SEPOLIA_KEY_HASH,
      500_000,
      1,
      "TestNFT",
      "TNFT",
      SEPOLIA_SUBS_ID,
      ethers.parseEther("0.01"),
      5
    ) as unknown as NFTcontract;
    await nft.waitForDeployment();
  });

  it("Should mint on Sepolia and eventually emit RandomNumberFulfilled", async function () {
    this.timeout(120_000);
    const cost = await nft.getMintingCost();

    const tx = await nft.requestRandomNumber({ value: cost, gasLimit: 2_000_000 });
    const receipt = (await tx.wait())!;
    const reqLog = receipt.logs
      .map(l => { try { return nft.interface.parseLog(l) } catch { return null } })
      .find(e => e?.name === "RandomNumberRequested");
    expect(reqLog).to.not.be.undefined;
    const tokenId = reqLog!.args.tokenId;

    await new Promise<void>((resolve, reject) => {
      const filter = nft.filters.RandomNumberFulfilled();
      nft.once(
        filter,
        (tokenId, randomNumber, event) => {
          try {
            expect(tokenId).to.equal(tokenId);
            expect(randomNumber).to.be.at.least(0).and.lessThan(25);
            resolve();
          } catch (err) {
            reject(err);
          }
        }
      );
      setTimeout(() => reject(new Error("Timeout waiting VRF")), 90_000);
    });

    const uri     = await nft.tokenURI(tokenId);
    expect(uri).to.match(/^data:application\/json;base64,/);
    const base64  = uri.split(",")[1].trim();
    const jsonStr = Buffer.from(base64, "base64").toString("utf8").trim();
    const meta    = JSON.parse(jsonStr);
    expect(meta).to.include.keys("City", "Lucky Number", "Tour Chance");
  });
});
