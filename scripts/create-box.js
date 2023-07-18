// scripts/create-box.js
const { ethers, upgrades } = require("hardhat");
// const employerBadgeAddress = "0xbA48b6AC88761d8B153E50Ca882FB4Ae798f57df";
const employerBadgeAddress = "0x9452B6f7726214cc6BFD04c6145033D113A78eC4";
async function main() {
    console.log("Starting...");
    const EmployeeBadge = await ethers.getContractFactory("EmployeeBadge");
    const employeeBadge = await upgrades.deployProxy(EmployeeBadge, [employerBadgeAddress]);
    console.log("Deploying EmployeeBadge...");
    await employeeBadge.deployed();
    console.log("EmployeeBadge deployed to:", employeeBadge.address);
}

main();
