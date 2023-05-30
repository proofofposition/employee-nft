//
// this script executes when you run 'yarn test'
//
// you can also test remote submissions like:
// CONTRACT_ADDRESS=0x43Ab1FCd430C1f20270C2470f857f7a006117bbb yarn test --network rinkeby
//
// you can even run mint commands if the tests pass like:
// yarn test && echo "PASSED" || echo "FAILED"
//
const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("🚩Employee Badge User Flows", function () {
    this.timeout(120000);

    let myContract;
    let owner;
    let alice;
    let bob;

    // console.log("hre:",Object.keys(hre)) // <-- you can access the hardhat runtime env here

    describe("EmployeeBadge", function () {
        // `beforeEach` will run before each test, re-deploying the contract every
        // time. It receives a callback, which can be async.
        beforeEach(async function () {
            const Popp = await ethers.getContractFactory("EmployeeBadge");
            const EmployerSftMockFactory = await ethers.getContractFactory("EmployerSftMock");
            const TokenMockFactory = await ethers.getContractFactory("TokenMock");
            const PriceOracleMockFactory = await ethers.getContractFactory("PriceOracleMock");
            this.employerSft = await EmployerSftMockFactory.deploy();
            this.erc20 = await TokenMockFactory.deploy();
            this.priceOracle = await PriceOracleMockFactory.deploy(67);

            myContract = await Popp.deploy(this.employerSft.address, this.erc20.address, this.priceOracle.address);

            [owner, alice, bob] = await ethers.getSigners();
            expect(await this.erc20.balanceOf(owner.address)).to.equal(
                1000000000000000000000000n
            );
        });

        describe("mintFor() ", function () {
            it("Should be able to approve an employee to mint", async function () {
                await this.employerSft.setEmployerId(1);
                await myContract.approveMint(
                    alice.address,
                    "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr"
                );

                await myContract.connect(alice).mintFor(alice.address, 1);
                const aliceBalance = await myContract.balanceOf(alice.address);
                const jobId = await myContract.getJobIdFromEmployeeAndEmployer(alice.address, 1);
                expect(aliceBalance.toBigInt()).to.equal(1);
                expect(jobId.toBigInt()).to.equal(1);

                await expect(
                    myContract.connect(alice).transferFrom(alice.address, bob.address, 1)
                ).to.be.revertedWith("POPP is non-transferable");
            });

            it("Should be able to approve an employee to mint several popp badges", async function () {
                await this.employerSft.setEmployerId(1);
                await myContract.approveMint(
                    alice.address,
                    "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr"
                );

                await myContract.connect(alice).mintFor(alice.address, 1);
                let aliceBalance = await myContract.balanceOf(alice.address);
                let jobId = await myContract.getJobIdFromEmployeeAndEmployer(alice.address, 1);
                expect(aliceBalance.toBigInt()).to.equal(1);
                expect(jobId.toBigInt()).to.equal(1);

                // mint for another employer
                await this.employerSft.setEmployerId(2);
                await myContract.approveMint(
                    alice.address,
                    "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr"
                );
                await myContract.connect(alice).mintFor(alice.address, 2);
                aliceBalance = await myContract.balanceOf(alice.address);
                jobId = await myContract.getJobIdFromEmployeeAndEmployer(alice.address, 2);
                expect(aliceBalance.toBigInt()).to.equal(2);
                expect(jobId.toBigInt()).to.equal(2);
            });

            it("Should be able to overwrite badges from the same employer", async function () {
                await this.employerSft.setEmployerId(1);
                await myContract.approveMint(
                    alice.address,
                    "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr"
                );

                await myContract.connect(alice).mintFor(alice.address, 1);
                let aliceBalance = await myContract.balanceOf(alice.address);
                let jobId = await myContract.getJobIdFromEmployeeAndEmployer(alice.address, 1);
                expect(aliceBalance.toBigInt()).to.equal(1);
                expect(jobId.toBigInt()).to.equal(1);

                // mint for same employer
                await myContract.approveMint(
                    alice.address,
                    "another-hash"
                );
                await myContract.connect(alice).mintFor(alice.address, 1);
                aliceBalance = await myContract.balanceOf(alice.address);
                jobId = await myContract.getJobIdFromEmployeeAndEmployer(alice.address, 1);
                expect(aliceBalance.toBigInt()).to.equal(1);
                expect(jobId.toBigInt()).to.equal(2);
            });

            it("Should not be able to mint without approval", async function () {
                // test no approval
                await expect(
                    myContract.connect(bob).mintFor(bob.address, 1)
                ).to.be.revertedWith("employee doesn't have approval to mint");
                const bobBalance = await myContract.balanceOf(bob.address);
                expect(bobBalance.toBigInt()).to.equal(0);
            });
        });

        describe("burn()", function () {
            it("Should be able to burn your popp", async function () {
                await this.employerSft.setEmployerId(1);
                await myContract.approveMint(
                    alice.address,
                    "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr"
                );

                await myContract.connect(alice).mintFor(alice.address, 1);

                await myContract.connect(alice).burn(1);
                const aliceBalance = await myContract.balanceOf(alice.address);
                expect(aliceBalance.toBigInt()).to.equal(0);
            });
            it("Should be able to burn your employee's pop", async function () {
                await this.employerSft.setEmployerId(1);
                await myContract.approveMint(
                    alice.address,
                    "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr"
                );

                await myContract.connect(alice).mintFor(alice.address, 1);
                await this.employerSft.setEmployerId(2);
                await expect(
                    myContract.connect(bob).burn(1)
                ).to.be.revertedWith("Only the employee or employer can do this");

                await this.employerSft.setEmployerId(1);
                await myContract.connect(bob).burn(1);
                const aliceBalance = await myContract.balanceOf(alice.address);
                expect(aliceBalance.toBigInt()).to.equal(0);
            });
        });

        describe("deleteMintApproval()", function () {
            it("Should be able delete mint approval as an employer", async function () {
                await this.employerSft.setEmployerId(1);
                await myContract.approveMint(
                    alice.address,
                    "deleted-hash"
                );
                let canMint = await myContract.canMintJob("deleted-hash", alice.address, 1);
                expect(canMint).to.equal(true);
                await this.employerSft.setEmployerId(2);
                // bob here will be mocked as employer id 2
                await expect(
                    myContract.connect(bob).deleteMintApproval(alice.address, 1)
                ).to.be.revertedWith("You don't have permission to delete this approval");

                await this.employerSft.setEmployerId(1);
                await myContract.connect(bob).deleteMintApproval(alice.address, 1)
                canMint = await myContract.canMintJob("deleted-hash", alice.address, 1);
                expect(canMint).to.equal(false);
            });

            it("Should be able delete mint approval as an employee", async function () {
                await this.employerSft.setEmployerId(1);
                await myContract.approveMint(
                    alice.address,
                    "deleted-hash"
                );
                let canMint = await myContract.canMintJob("deleted-hash", alice.address, 1);
                expect(canMint).to.equal(true);
                await this.employerSft.setEmployerId(2);
                // bob here will be mocked as employer id 2
                await expect(
                    myContract.connect(bob).deleteMintApproval(alice.address, 1)
                ).to.be.revertedWith("You don't have permission to delete this approval");

                await myContract.connect(alice).deleteMintApproval(alice.address, 1)
                canMint = await myContract.canMintJob("deleted-hash", alice.address, 1);
                expect(canMint).to.equal(false);
            });
        });

        describe("sePrice() ", function () {
            it("Should be able to set the price", async function () {
                await myContract.connect(owner).setPrice(100);
                expect(await myContract.getPrice()).to.equal(
                    100
                );
            });

            it("Should not be able to set the price as a non-owner", async function () {
                await expect(
                    myContract.connect(alice).setPrice(100)
                ).to.be.revertedWith("Ownable: caller is not the owner");
            });
        });

        describe("paid approveMint() ", function () {
            it("Should be able to approve an employee to mint and pay the fee", async function () {
                await this.employerSft.setEmployerId(1);
                await myContract.connect(owner).setPrice(345);

                await this.erc20.connect(owner).transfer(bob.address, 5149253731343283582n);
                let fee = await myContract.getTokenFee();
                await this.erc20.connect(bob).approve(myContract.address, fee);

                expect(fee/(10**18)).to.equal(
                    5.149253731343284 // $POPP
                );

                await myContract.connect(bob).approveMint(
                    alice.address,
                    "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr"
                );

                let canMint = await myContract.canMintJob("QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr", alice.address, 1);
                expect(canMint).to.equal(true);

                expect(await this.erc20.balanceOf(bob.address)).to.equal(
                    0
                );

            });
        });

        describe("selfDestruct() ", function () {
            it("Owner should be able to destruct contract", async function () {
                await owner.sendTransaction({
                    to: myContract.address,
                    value: ethers.utils.parseEther("10"), // Sends exactly 1.0 ether
                });
                expect((await myContract.provider.getBalance(myContract.address)).toBigInt()).to.equal(
                    10000000000000000000n
                );
            });
        });

    });
});
