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

describe("🚩 Job NFT User Flows", function () {
    this.timeout(120000);

    let myContract;
    let owner;
    let alice;
    let bob;

    // console.log("hre:",Object.keys(hre)) // <-- you can access the hardhat runtime env here

    describe("JobNFT", function () {
        // `beforeEach` will run before each test, re-deploying the contract every
        // time. It receives a callback, which can be async.
        beforeEach(async function () {
            const Popp = await ethers.getContractFactory("JobNFT");
            const EmployerSftMockFactory = await ethers.getContractFactory("EmployerSftMock");
            this.employerSft = await EmployerSftMockFactory.deploy();

            myContract = await Popp.deploy(this.employerSft.address);

            [owner, alice, bob] = await ethers.getSigners();
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
                ).to.be.revertedWith("you don't have approval to mint");
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
    });
});
