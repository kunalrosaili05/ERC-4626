import hre from "hardhat";

async function main() {
  const { ethers } = hre;

  if (!ethers) {
    throw new Error("ethers is undefined. Check hardhat-ethers plugin installation.");
  }

  const [deployer] = await ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  // 1. Deploy MockUSDC
  const MockUSDC = await ethers.getContractFactory("MockUSDC");
  const usdc = await MockUSDC.deploy();
  await usdc.waitForDeployment();
  console.log("MockUSDC deployed at:", usdc.target);

  // 2. Deploy Vault
  const Vault = await ethers.getContractFactory("Vault");
  const vault = await Vault.deploy(usdc.target);
  await vault.waitForDeployment();
  console.log("Vault deployed at:", vault.target);

  // 3. Deploy Strategies
  const StrategyA = await ethers.getContractFactory("StrategyA");
  const strategyA = await StrategyA.deploy(usdc.target, vault.target);
  await strategyA.waitForDeployment();
  console.log("StrategyA deployed at:", strategyA.target);

  const StrategyB = await ethers.getContractFactory("StrategyB");
  const strategyB = await StrategyB.deploy(usdc.target, vault.target);
  await strategyB.waitForDeployment();
  console.log("StrategyB deployed at:", strategyB.target);

  // 4. Register strategies
  const MANAGER_ROLE = await vault.MANAGER_ROLE();
  await vault.grantRole(MANAGER_ROLE, deployer.address);

  await vault.addStrategy(strategyA.target, 6000);
  await vault.addStrategy(strategyB.target, 4000);
  console.log("Strategies registered");

  // 5. Initial rebalance
  await vault.rebalance();
  console.log("Initial rebalance done");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
