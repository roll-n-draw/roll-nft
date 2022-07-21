//  "Check second value of event. Accepts any value for first value.",
const hre = require("hardhat");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");

async function main() {

    const currentTimestampInSeconds = Math.round(Date.now() / 1000);
    const TWO_HOURS_IN_SECS = 365 * 24 * 60 * 60;
    const ONE_OUR_IN_SECS = 10;
    const startTime = currentTimestampInSeconds + ONE_OUR_IN_SECS;
    const endTime = currentTimestampInSeconds + TWO_HOURS_IN_SECS;
    
    const lockedAmount = hre.ethers.utils.parseEther("1");

    const RollHub = await hre.ethers.getContractFactory("Lock");
    const rollHub = await RollHub.deploy(unlockTime, { value: lockedAmount });

    await rollHub.deployed();

    await expect(rollHub.createRoll())
    .to.emit(rollHub, "RollPublished")
    .withArgs(anyValue, 3);
}