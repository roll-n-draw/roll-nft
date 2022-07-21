require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const mnemonic = process.env.MNEMONIC; 

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    mumbai: {
      url: process.env.INFURA_API_URL,
      //accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 35000000000,
    },
    rinkeby: {
      url: process.env.RINKEBY_ALCHEMY,
      accounts: {mnemonic, },
    },
  },
};
