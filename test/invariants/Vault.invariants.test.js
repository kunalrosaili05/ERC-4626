const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deployFixture } = require("../helpers/deploy");

describe("Vault – Invariant Tests", function () {
  let deployer, user, manager;
  let usdc, vault, strategyA, strategyB;

  const DEPOSIT_AMOUNT = ethers.parseUnits("1000", 6);

  beforeEach(async () => {
    ({
      deployer,
      user,
      usdc,
      vault,
      strategyA,
      strategyB,
    } = await deployFixture());

    manager = deployer;

    // Fund user
    await usdc.transfer(user.address, ethers.parseUnits("2000", 6));
  });

  it("Invariant: totalAssets >= strategy debt + idle", async () => {
    await usdc.connect(user).approve(vault.target, DEPOSIT_AMOUNT);
    await vault.connect(user).deposit(DEPOSIT_AMOUNT, user.address);

    const totalAssets = await vault.totalAssets();
    const debtA = await vault.strategyDebt(strategyA.target);
    const debtB = await vault.strategyDebt(strategyB.target);
    const idle = await usdc.balanceOf(vault.target);

    expect(totalAssets).to.be.gte(debtA + debtB);
    expect(totalAssets).to.be.gte(idle);
  });

  it("Invariant: share price reflects totalAssets", async () => {
    await usdc.connect(user).approve(vault.target, DEPOSIT_AMOUNT);
    await vault.connect(user).deposit(DEPOSIT_AMOUNT, user.address);

    await vault
  .connect(manager)
  .simulateStrategyYield(
    strategyA.target,
    ethers.parseUnits("60", 6)
  );

    const totalSupply = await vault.totalSupply();
    const assetsFromShares = await vault.convertToAssets(totalSupply);
    const totalAssets = await vault.totalAssets();

    expect(assetsFromShares).to.be.closeTo(
      totalAssets,
      ethers.parseUnits("1", 6)
    );
  });

  it("Invariant: withdraw burns shares", async () => {
    await usdc.connect(user).approve(vault.target, DEPOSIT_AMOUNT);
    await vault.connect(user).deposit(DEPOSIT_AMOUNT, user.address);

    await vault.connect(user).withdraw(
      DEPOSIT_AMOUNT,
      user.address,
      user.address
    );

    expect(await vault.balanceOf(user.address)).to.equal(0n);
  });

  it("Invariant: strategies cannot be drained by non-vault", async () => {
    await expect(
      strategyA.connect(user).withdraw(1)
    ).to.be.revertedWith("Only vault");
  });
});
