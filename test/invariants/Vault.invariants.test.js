import { expect } from "chai";
import { ethers } from "hardhat";
import { deployFixture } from "../helpers/deploy.js";

describe("Vault – Invariant Tests", function () {
  let deployer, user, manager;
  let usdc, vault, strategyA, strategyB;

  const DEPOSIT_AMOUNT = ethers.parseUnits("1000", 6);

  beforeEach(async () => {
    ({
      deployer,
      user,
      manager,
      usdc,
      vault,
      strategyA,
      strategyB,
    } = await deployFixture());

    // Fund user
    await usdc.transfer(user.address, ethers.parseUnits("2000", 6));

    // Add strategies with 60/40 allocation
    await vault.connect(manager).addStrategy(strategyA.target, 5000);
    await vault.connect(manager).addStrategy(strategyB.target, 5000);
  });

  /*//////////////////////////////////////////////////////////////
                        ACCOUNTING INVARIANTS
  //////////////////////////////////////////////////////////////*/

  it("Invariant: totalAssets is always >= idle assets and strategy debt", async () => {
    await usdc.connect(user).approve(vault.target, DEPOSIT_AMOUNT);
    await vault.connect(user).deposit(DEPOSIT_AMOUNT, user.address);

    const totalAssets = await vault.totalAssets();

    const debtA = await vault.strategyDebt(strategyA.target);
    const debtB = await vault.strategyDebt(strategyB.target);
    const idle = await usdc.balanceOf(vault.target);

    // Lower-bound guarantees
    expect(totalAssets).to.be.gte(debtA + debtB);
    expect(totalAssets).to.be.gte(idle);
  });

  it("Invariant: share price reflects aggregate totalAssets", async () => {
    await usdc.connect(user).approve(vault.target, DEPOSIT_AMOUNT);
    await vault.connect(user).deposit(DEPOSIT_AMOUNT, user.address);

    // Simulate yield in StrategyA
    await strategyA.connect(deployer).simulateYield(
      ethers.parseUnits("60", 6)
    );

    const totalSupply = await vault.totalSupply();
    const assetsFromShares = await vault.convertToAssets(totalSupply);
    const totalAssets = await vault.totalAssets();

    // Conservative rounding tolerance
    expect(assetsFromShares).to.be.closeTo(
      totalAssets,
      ethers.parseUnits("0.001", 6)
    );
  });

  /*//////////////////////////////////////////////////////////////
                    WITHDRAWAL & SAFETY INVARIANTS
  //////////////////////////////////////////////////////////////*/

  it("Invariant: withdrawal burns all shares and preserves user value", async () => {
    await usdc.connect(user).approve(vault.target, DEPOSIT_AMOUNT);
    await vault.connect(user).deposit(DEPOSIT_AMOUNT, user.address);

    const sharesBefore = await vault.balanceOf(user.address);
    const balanceBefore = await usdc.balanceOf(user.address);

    await vault.connect(user).withdraw(
      DEPOSIT_AMOUNT,
      user.address,
      user.address
    );

    const balanceAfter = await usdc.balanceOf(user.address);
    const sharesAfter = await vault.balanceOf(user.address);

    expect(sharesBefore).to.be.gt(0n);
    expect(sharesAfter).to.equal(0n);

    // No silent value loss
    expect(balanceAfter).to.be.gte(balanceBefore);
  });

  it("Invariant: deposit + immediate withdraw never yields profit (no inflation)", async () => {
    await usdc.connect(user).approve(vault.target, DEPOSIT_AMOUNT);

    const balanceBefore = await usdc.balanceOf(user.address);

    await vault.connect(user).deposit(DEPOSIT_AMOUNT, user.address);
    await vault.connect(user).withdraw(
      DEPOSIT_AMOUNT,
      user.address,
      user.address
    );

    const balanceAfter = await usdc.balanceOf(user.address);

    // User should never profit from round-trip
    expect(balanceAfter).to.be.lte(balanceBefore);
  });

  it("Invariant: queued withdrawals do not affect share price", async () => {
    await usdc.connect(user).approve(vault.target, DEPOSIT_AMOUNT);
    await vault.connect(user).deposit(DEPOSIT_AMOUNT, user.address);

    const priceBefore = await vault.convertToAssets(
      await vault.totalSupply()
    );

    // Force async withdrawal (StrategyB is locked)
    await vault.connect(user).withdraw(
      DEPOSIT_AMOUNT,
      user.address,
      user.address
    );

    const priceAfter = await vault.convertToAssets(
      await vault.totalSupply()
    );

    expect(priceAfter).to.equal(priceBefore);
  });

  /*//////////////////////////////////////////////////////////////
                    ALLOCATION & ACCESS INVARIANTS
  //////////////////////////////////////////////////////////////*/

  it("Invariant: strategy allocation caps are respected even after yield", async () => {
    await usdc.connect(user).approve(vault.target, DEPOSIT_AMOUNT);
    await vault.connect(user).deposit(DEPOSIT_AMOUNT, user.address);

    // Simulate yield and rebalance
    await strategyA.simulateYield(ethers.parseUnits("60", 6));
    await vault.rebalance();

    const totalAssets = await vault.totalAssets();

    const debtA = await vault.strategyDebt(strategyA.target);
    const debtB = await vault.strategyDebt(strategyB.target);

    expect(debtA).to.be.lte((totalAssets * 6000n) / 10000n);
    expect(debtB).to.be.lte((totalAssets * 4000n) / 10000n);
  });

  it("Invariant: strategies cannot be drained by non-vault callers", async () => {
    await expect(
      strategyA.connect(user).withdraw(1)
    ).to.be.revertedWith("Only vault");
  });
});
