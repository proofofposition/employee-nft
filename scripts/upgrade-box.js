const { ethers, upgrades } = require("hardhat");
const UPGRADEABLE_CONTRACT_ADDRESS = "0xEc1c73060efd5dd5283AfF81eA5EaE03eA4d512D";
async function main() {
    console.log("Starting...");
    const EmployeeBadge = await ethers.getContractFactory("EmployeeBadge");
    console.log("Deploying EmployeeBadge...");
    const employeeBadge = await upgrades.upgradeProxy(UPGRADEABLE_CONTRACT_ADDRESS, EmployeeBadge);
    console.log("EmployeeBadge upgraded at :", employeeBadge);
}

main();