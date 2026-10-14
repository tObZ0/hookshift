const { expect } = require("chai");
const { ethers } = require("hardhat");
describe("HookShiftTreasury", function () {
  let treasury, owner, recipient, stranger;
  beforeEach(async function () {
    [owner, recipient, stranger] = await ethers.getSigners();
    treasury = await ethers.deployContract("HookShiftTreasury", [owner.address, 3600, 1000]);
    await treasury.waitForDeployment();
    await owner.sendTransaction({to: await treasury.getAddress(), value: ethers.parseEther("10")});
    await treasury.setRecipient(recipient.address, true);
  });
  it("rejects unauthorized proposal", async () => {
    await expect(treasury.connect(stranger).propose(recipient.address, 1)).to.be.revertedWith("owner only");
  });
  it("enforces delay and allows permitted execution", async () => {
    await treasury.propose(recipient.address, ethers.parseEther("0.5"));
    await expect(treasury.execute(1)).to.be.revertedWith("timelocked");
    await ethers.provider.send("evm_increaseTime", [3601]);
    await ethers.provider.send("evm_mine", []);
    await expect(treasury.execute(1)).to.emit(treasury, "Executed");
  });
  it("enforces daily spending cap", async () => {
    await treasury.propose(recipient.address, ethers.parseEther("2"));
    await ethers.provider.send("evm_increaseTime", [3601]);
    await ethers.provider.send("evm_mine", []);
    await expect(treasury.execute(1)).to.be.revertedWith("daily cap exceeded");
  });
  it("allows cancellation and emergency pause", async () => {
    await treasury.propose(recipient.address, ethers.parseEther("0.1"));
    await treasury.cancel(1);
    await expect(treasury.execute(1)).to.be.revertedWith("not pending");
    await treasury.setPaused(true);
    await expect(treasury.propose(recipient.address, 1)).to.be.revertedWith("paused");
  });
  it("rejects removed recipient at execution", async () => {
    await treasury.propose(recipient.address, ethers.parseEther("0.1"));
    await treasury.setRecipient(recipient.address, false);
    await ethers.provider.send("evm_increaseTime", [3601]);
    await ethers.provider.send("evm_mine", []);
    await expect(treasury.execute(1)).to.be.revertedWith("recipient not allowed");
  });
});