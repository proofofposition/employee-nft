const { ethers, upgrades } = require("hardhat");
// goerli
//const UPGRADEABLE_CONTRACT_ADDRESS = "0xEc1c73060efd5dd5283AfF81eA5EaE03eA4d512D";
// sepolia
const UPGRADEABLE_CONTRACT_ADDRESS = "0x09daCDAb31054ccF6e521f026947937C24259ea4";
// base goerli
// const UPGRADEABLE_CONTRACT_ADDRESS = "0x71763e216f4C68e8865F8dd1f060E2f1C5fb14c3";
async function main() {
    console.log("Starting...");
    const EmployeeNft = await ethers.getContractFactory("EmployeeNft");
    console.log("Deploying EmployeeNft...");
    const employeeNft = await upgrades.upgradeProxy(UPGRADEABLE_CONTRACT_ADDRESS, EmployeeNft);
    console.log("EmployeeNft upgraded at :", employeeNft);
}

main();