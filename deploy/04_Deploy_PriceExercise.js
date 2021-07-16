let { networkConfig } = require("../helper-hardhat-config");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log, get } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();
  let linkTokenAddress;
  let oracle;
  let additionalMessage = "";
  //set log level to ignore non errors
  ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR);
  let btcUsdPriceFeedAddress = "0x6135b13325bfC4B00278B4abC5e20bbce2D6580e";

  if (chainId == 31337) {
    let linkToken = await get("LinkToken");
    let MockOracle = await get("MockOracle");
    linkTokenAddress = linkToken.address;
    oracle = MockOracle.address;
    let additionalMessage = " --linkaddress " + linkTokenAddress;
  } else {
    linkTokenAddress = networkConfig[chainId]["linkToken"];
    oracle = networkConfig[chainId]["oracle"];
  }
  const jobId = networkConfig[chainId]["jobId"];
  const fee = networkConfig[chainId]["fee"];
  const networkName = networkConfig[chainId]["name"];

  const priceExerciseContract = await deploy("PriceExercise", {
    from: deployer,
    args: [oracle, jobId, fee, linkTokenAddress, btcUsdPriceFeedAddress],
    log: true,
  });
};
module.exports.tags = ["all", "api", "main"];
