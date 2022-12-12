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

        describe("mintItem() ", function () {
            it("Should be able to approve an employee to mint", async function () {
                await this.employerSft.setEmployerId(1);
                await myContract.approveMint(
                    alice.address,
                    "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr"
                );

                await myContract.connect(alice).mintItem(alice.address);
                const aliceBalance = await myContract.balanceOf(alice.address);
                const jobId = await myContract.getJobIdFromEmployee(alice.address);
                expect(aliceBalance.toBigInt()).to.equal(1);
                expect(jobId.toBigInt()).to.equal(1);

                await expect(
                    myContract.connect(alice).transferFrom(alice.address, bob.address, 1)
                ).to.be.revertedWith("POPP is non-transferable");
            });

            it("Should not be able to mint without approval", async function () {
                // test no approval
                await expect(
                    myContract.connect(bob).mintItem(bob.address)
                ).to.be.revertedWith("you don't have approval to mint this NFT");
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

                await myContract.connect(alice).mintItem(alice.address);

                await expect(
                    myContract.connect(bob).burn(1)
                ).to.be.revertedWith("Only the owner can do this");

                await myContract.connect(alice).burn(1);
                const aliceBalance = await myContract.balanceOf(alice.address);
                expect(aliceBalance.toBigInt()).to.equal(0);
            });
        });

    });
});
