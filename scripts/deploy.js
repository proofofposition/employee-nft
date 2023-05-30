async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Contract = await ethers.getContractFactory("EmployeeBadge");
  const contract = await Contract.deploy(
      '0x40df9a8F59D7e1622Ad9132FF4CDE690106ED1bC' // EmployerSft
  );

  console.log("Token address:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
