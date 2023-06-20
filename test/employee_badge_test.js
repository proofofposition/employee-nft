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

    describe("EmployeeBadge", function () {
        beforeEach(async function () {
            // deploy employer badge mock contract
            const EmployerSftMockFactory = await ethers.getContractFactory("EmployerSftMock");
            this.employerSft = await upgrades.deployProxy(EmployerSftMockFactory);
            // deploy contract under test
            const Popp = await ethers.getContractFactory("EmployeeBadge");
            myContract = await upgrades.deployProxy(Popp, [this.employerSft.address]);

            [owner, alice, bob] = await ethers.getSigners();
        });

        describe("mintFor() ", function () {
            it("Should be able to mint for an employee", async function () {
                await this.employerSft.setEmployerId(1);
                await myContract.mintFor(
                    alice.address,
                    "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr"
                );

                expect(await myContract.balanceOf(alice.address)).to.equal(1);
                expect(await myContract.ownerOf(1)).to.equal(alice.address);
                expect(await myContract.getEmployerId(1)).to.equal(1);

                await expect(
                    myContract.connect(alice).transferFrom(alice.address, bob.address, 1)
                ).to.be.revertedWith("POPP is non-transferable");
            });

            it("Should not be able to mint without employee token", async function () {
                // test no approval
                await expect(
                    myContract.connect(bob).mintFor(bob.address, 'QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr')
                ).to.be.revertedWith("You need to be a POPP verified employer to do this.");
                const bobBalance = await myContract.balanceOf(bob.address);
                expect(bobBalance.toBigInt()).to.equal(0);
            });
        });

        describe("adminMintFor() ", function () {
            it("Should be able to mint for an employee as an admin", async function () {
                await myContract.adminMintFor(
                    alice.address,
                    "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr",
                    1
                );

                expect(await myContract.balanceOf(alice.address)).to.equal(1);
                expect(await myContract.ownerOf(1)).to.equal(alice.address);
            });

            it("Should not be able to use the admin function as a non admin", async function () {
                // test no approval
                await expect(
                    myContract.connect(bob).adminMintFor(
                        bob.address,
                        'QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr',
                        1
                    )
                ).to.be.revertedWith("Ownable: caller is not the owner");
                const bobBalance = await myContract.balanceOf(bob.address);
                expect(bobBalance.toBigInt()).to.equal(0);
            });
        });

        describe("burn()", function () {
            it("Should be able to burn your popp", async function () {
                await this.employerSft.setEmployerId(1);
                await myContract.mintFor(
                    alice.address,
                    "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr"
                );

                await myContract.connect(alice).burn(1);
                const aliceBalance = await myContract.balanceOf(alice.address);
                expect(aliceBalance.toBigInt()).to.equal(0);
            });
            it("Should be able to burn your employee's pop", async function () {
                await this.employerSft.setEmployerId(1);
                await myContract.mintFor(
                    alice.address,
                    "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr"
                );

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
