const { ethers, upgrades } = require("hardhat");
const UPGRADEABLE_CONTRACT_ADDRESS = "0x6AD61192B4a732e4ce54A68c5c993370490EA042";
async function main() {
    console.log("Starting...");
    const EmployeeBadge = await ethers.getContractFactory("EmployeeBadge");
    console.log("Deploying EmployeeBadge...");
    const employeeBadge = await upgrades.upgradeProxy(UPGRADEABLE_CONTRACT_ADDRESS, EmployeeBadge);
    console.log("EmployeeBadge upgraded at :", employeeBadge);
}

main();