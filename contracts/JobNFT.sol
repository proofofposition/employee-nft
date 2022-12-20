// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "popp-interfaces/IEmployerSft.sol";
import "popp-interfaces/IJobNFT.sol";

// Desired Features
// - Approve minting of new job NFTs done by the employer
// - Mint new job NFTs
// - Check if a given wallet can mint a job NFT
// - Burn Tokens
// - ERC721 full interface (base, metadata, enumerable)
contract JobNFT is
ERC721,
ERC721URIStorage,
Ownable,
IJobNFT
{
    IEmployerSft employerSft;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    mapping(address => mapping(uint32 => MintApproval)) employeeToApprovals;
    mapping(address =>  mapping(uint32 => uint256)) employeeToJobIds;
    mapping(uint256 => uint32) jobToEmployerId;

    struct MintApproval {
        string uri;
        uint32 employerId;
    }

    /**
     * @dev We use the employer SFT to map a wallet to an employer sft
     */
    constructor(address _employerSftAddress) ERC721("Proof Of Position", "POPP") {
        employerSft = IEmployerSft(_employerSftAddress);
    }

    /**
     * @dev Create approval for an employee to mint.
     * It is important to save the employerId here for verification of the badge
     * @param to The employee to grant mint approval
     * @param uri The uri of the job badge nft
     */
    function approveMint(
        address to,
        string memory uri
    ) public {
        uint32 employerId = getSendersEmployerId();
        MintApproval memory existingApproval = getApproval(to,employerId);
        require(existingApproval.employerId == 0, "Approval already exists for this employer");

        require(employerId != 0, "You need to be an employer to approve");
        MintApproval memory approval = MintApproval(
            uri,
            employerId
        );

        employeeToApprovals[to][employerId] = approval;
    }

    /**
     * @dev Delete a mint approval for an employee
     * @param to The address for which the approval should be deleted
     * @param employerId The employerId for which the approval should be deleted
     */
    function deleteMintApproval(
        address to,
        uint32 employerId
    ) public {
        require(
            _msgSender() == to
            || _msgSender() == owner()
            || getSendersEmployerId() == employerId
        ,
            "You don't have permission to delete this approval"
        );

        delete employeeToApprovals[employee][employerId];
    }

    /**
     * @dev Mint a new pre-approved job NFT. This handles the minting pre-existing and new jobs
     * It's worth noting that an employee can only hold one badge per employer.
     * A pre-existing badge gets overwritten by the next
     * @param to The address to mint the NFT to
     * @param employerId The ID of the employer of this job
     */
    function mintFor(address _employee, uint32 _employerId) public {
        MintApproval memory approval = getApproval(_employee, _employerId);

        require(approval.employerId == _employerId, "you don't have approval to mint");
        if (employeeToJobIds[_employee][_employerId] != 0) {
            // If the employee already has a job NFT for this employer, burn it
            _burn(employeeToJobIds[_employee][_employerId]);
        }

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(_employee, tokenId);
        _setTokenURI(tokenId, approval.uri);

        jobToEmployerId[tokenId] = approval.employerId;
        employeeToJobIds[_employee][approval.employerId] = tokenId;

        delete employeeToApprovals[_employee][approval.employerId];
    }

    /**
     * @dev Can a given employee mint a job with
     * @param _uri The uri of the job badge nft
     * @param _minter The address of the minter (employee)
     * @param _employerId The ID of the employer of this job
     * @return true if the employee can mint a job with the given uri and employerId
     */
    function canMintJob(string memory _uri, address _minter, uint32 _employerId ) external view returns (bool){
        MintApproval memory approval = getApproval(_minter, _employerId);

        return keccak256(abi.encodePacked(approval.uri)) == keccak256(abi.encodePacked(_uri))
            && approval.employerId == _employerId;
    }

    /**
     * @dev Get the approval for a given employee
     * @param _employee The employee to get the approval for
     * @param _employerId The employerId to get the approval for
     * @return The approval for the given employee and employerId
     */
    function getApproval(address employee, uint32 employerId) public view returns (MintApproval memory) {
        return employeeToApprovals[employee][employerId];
    }

    /**
     * @dev Get the employerId from a job ID
     * @param _jobId The jobId to get the employerId for
     * @return The employerId for the given jobId
     */
    function getEmployerIdFromJobId(uint256 _jobId) public view returns (uint32) {
        return jobToEmployerId[_jobId];
    }

    /**
     * @dev Get the job id of the given employee at a employer
     * @param _employee The employee to get the job id for
     * @param _employerId The employerId to get the job id for
     * @return The job id for the given employee and employerId
     */
    function getJobIdFromEmployeeAndEmployer(address _employee, uint32 _employerId) external view returns (uint256) {
        return employeeToJobIds[_employee][_employerId];
    }

    /**
    * @dev Return the employer ID of the msg sender
    * @return The employer ID of the msg sender
    */
    function getSendersEmployerId() public view returns (uint32) {
        return employerSft.employerIdFromWallet(msg.sender);
    }
    /**
     * @dev Burn a token
     * @param tokenId The token to burn
     */
    function burn(uint256 tokenId) external {
        uint32 employerId = getEmployerIdFromJobId(tokenId);
        require(
            _msgSender() == ownerOf(tokenId)
            || owner() == _msgSender()
            || getSendersEmployerId() == employerId,
            "Only the employee or employer can do this"
        );
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual override(ERC721) {
        require(from == address(0) || to == address(0), "POPP is non-transferable");
    }

    function _burn(uint256 tokenId)
    internal
    override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, IERC165)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
