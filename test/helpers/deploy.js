const { ethers } = require("hardhat");

async function deployFixture() {
  const [deployer, user] = await ethers.getSigners();

  // Deploy MockUSDC
  const MockUSDC = await ethers.getContractFactory("MockUSDC");
  const usdc = await MockUSDC.deploy();
  await usdc.waitForDeployment();

  // Deploy Vault
  const Vault = await ethers.getContractFactory("Vault");
  const vault = await Vault.deploy(await usdc.getAddress());
  await vault.waitForDeployment();

  // Deploy strategies
  const StrategyA = await ethers.getContractFactory("StrategyA");
  const strategyA = await StrategyA.deploy(
    await usdc.getAddress(),
    await vault.getAddress()
  );
  await strategyA.waitForDeployment();

  const StrategyB = await ethers.getContractFactory("StrategyB");
  const strategyB = await StrategyB.deploy(
    await usdc.getAddress(),
    await vault.getAddress()
  );
  await strategyB.waitForDeployment();

  // ✅ Register strategies with ZERO allocation initially
  await vault.addStrategy(await strategyA.getAddress(), 0);
  await vault.addStrategy(await strategyB.getAddress(), 0);

  return {
    deployer,
    user,
    usdc,
    vault,
    strategyA,
    strategyB,
  };
}

module.exports = { deployFixture };
