/** @type import('hardhat/config').HardhatUserConfig */
require('hardhat-docgen');
module.exports = {
  solidity: "0.8.0",
  docgen: {
    path: './docs',
    clear: true,
    runOnCompile: true,
  }
};
