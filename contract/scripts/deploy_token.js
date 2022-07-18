const hre = require("hardhat");

async function main() {

  const TokenFactory = await hre.ethers.getContractFactory("RaffleERC721Token");
  const tokenContract = await TokenFactory.deploy();
  await tokenContract.deployed();

  console.log("Token contract deployed to:", tokenContract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
