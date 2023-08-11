// scripts/create-box.js
const { ethers, upgrades } = require("hardhat");
// sepolia
// const employerBadgeAddress = "0xb7D2887361C90DDf1f1B4630D222C1C9E477ed3d";
// base goerli
const employerBadgeAddress = "0x5c4033d014Fc6b99a2E2858c898608C93e93594E";
async function main() {
    console.log("Starting...");
    const EmployeeNft = await ethers.getContractFactory("EmployeeNft");
    const employeeNft = await upgrades.deployProxy(EmployeeNft, [employerBadgeAddress]);
    console.log("Deploying EmployeeNft...");
    await employeeNft.deployed();
    console.log("EmployeeNft deployed to:", employeeNft.address);
    let owner = await employeeNft.owner();
    console.log("Owner:", owner);
}

main();
