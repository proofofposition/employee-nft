// scripts/create-box.js
const { ethers, upgrades } = require("hardhat");
const employerBadgeAddress = "0xbA48b6AC88761d8B153E50Ca882FB4Ae798f57df";
async function main() {
    console.log("Starting...");
    const EmployeeBadge = await ethers.getContractFactory("EmployeeBadge");
    const employeeBadge = await upgrades.deployProxy(EmployeeBadge, [employerBadgeAddress]);
    console.log("Deploying EmployeeBadge...");
    await employeeBadge.deployed();
    console.log("EmployeeBadge deployed to:", employeeBadge.address);
}

main();
