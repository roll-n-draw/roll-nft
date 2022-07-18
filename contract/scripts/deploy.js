// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const VRF_COORDINATOR = "";
  const LINK_TOKEN = "";
  const SUBSCRIPTION_ID = "";
  const KEY_HASH = "";

  const raffle_start_time = "";
  const raffle_end_time = "";
  const token = "";
  const raffle_upper_limit = "";
  const raffle_lower_limit = "";
  const ticket_mint_cost = "";
  const prizes = [];

  const RaffleFactory = await hre.ethers.getContractFactory("RaffleFactory");
  const raffleFactory = await RaffleFactory.deploy(
    VRF_COORDINATOR, 
    LINK_TOKEN,
    SUBSCRIPTION_ID,
    KEY_HASH
    );
  const raffle = raffleFactory.createRollNFT(
    raffle_start_time,
    raffle_end_time,
    token,
    raffle_upper_limit,
    raffle_lower_limit,
    ticket_mint_cost,
    prizes
  )

  await raffleFactory.deployed();

  console.log("Raffle Factory deployed to:", raffleFactory.address);
  console.log("Raffle deployed to:", raffle.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
