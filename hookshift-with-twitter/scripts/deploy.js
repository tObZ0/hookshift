async function main() {
  const [deployer] = await ethers.getSigners();
  const factory = await ethers.getContractFactory("HookShiftTreasury");
  const treasury = await factory.deploy(deployer.address, 3600, 1000);
  await treasury.waitForDeployment();
  console.log("BNB TESTNET treasury:", await treasury.getAddress());
  console.log("Owner:", deployer.address);
  console.log("Do not send mainnet funds. Contract is not audited.");
}
main().catch(e => { console.error(e); process.exitCode = 1; });