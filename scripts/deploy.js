const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying with:", deployer.address);

  /*//////////////////////////////////////////////////////////////
                          Deploy Mock USDC
  //////////////////////////////////////////////////////////////*/

  const MockUSDC = await ethers.getContractFactory("MockUSDC");
  const usdc = await MockUSDC.deploy();
  await usdc.waitForDeployment();

  const usdcAddress = await usdc.getAddress();
  console.log("MockUSDC:", usdcAddress);

  /*//////////////////////////////////////////////////////////////
                            Deploy Vault
  //////////////////////////////////////////////////////////////*/

  const Vault = await ethers.getContractFactory("Vault");
  const vault = await Vault.deploy(usdcAddress);
  await vault.waitForDeployment();

  const vaultAddress = await vault.getAddress();
  console.log("Vault:", vaultAddress);

  /*//////////////////////////////////////////////////////////////
                          Deploy Strategies
  //////////////////////////////////////////////////////////////*/

  const StrategyA = await ethers.getContractFactory("StrategyA");
  const strategyA = await StrategyA.deploy(usdcAddress, vaultAddress);
  await strategyA.waitForDeployment();

  const strategyAAddress = await strategyA.getAddress();
  console.log("StrategyA:", strategyAAddress);

  const StrategyB = await ethers.getContractFactory("StrategyB");
  const strategyB = await StrategyB.deploy(usdcAddress, vaultAddress);
  await strategyB.waitForDeployment();

  const strategyBAddress = await strategyB.getAddress();
  console.log("StrategyB:", strategyBAddress);

  /*//////////////////////////////////////////////////////////////
                      Configure Vault (50 / 50)
  //////////////////////////////////////////////////////////////*/

  await vault.addStrategy(strategyAAddress, 5000);
  await vault.addStrategy(strategyBAddress, 5000);
  await vault.rebalance();


  console.log("Deployment complete");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
