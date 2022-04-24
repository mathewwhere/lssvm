
module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  networks: {
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.13",
      settings: {    
       optimizer: {
         enabled: true,
         runs: 200,
         details: {
          cse: true,
          constantOptimizer: true,
          yul: true,
          deduplicate: true
         }
       },
      }
    },
  },
  plugins: ["solidity-coverage"]
};
