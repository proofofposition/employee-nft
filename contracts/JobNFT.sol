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
    mapping(address => MintApproval) employeeToApproval;
    mapping(address => uint256) employeeToJob;
    mapping(uint256 => uint32) jobToEmployerId;

    struct MintApproval {
        string uri;
        uint32 employerTokenId;
    }

    /**
     * @dev We use the employer SFT to map a wallet to an employer sft
     */
    constructor(address _employerSftAddress) ERC721("Proof Of Position", "POPP") {
        employerSft = IEmployerSft(_employerSftAddress);
    }

    /**
     * @dev Create approval for an employee to mint.
     * It is important to save the employerTokenId here for verification of the badge
     */
    function approveMint(
        address employee,
        string memory uri
    ) public {
        uint32 employerTokenId = employerSft.employerIdFromWallet(_msgSender());
        require(employerTokenId != 0, "You need to be an employer to approve");
        MintApproval memory approval = MintApproval(
            uri,
            employerTokenId
        );
        employeeToApproval[employee] = approval;
    }

    /**
     * @dev An employee mint a pre-approved job NFT
     */
    function mintItem() public {
        address employee = _msgSender();
        MintApproval memory approval = getApproval(employee);

        require(approval.employerTokenId != 0, "you don't have approval to mint this NFT");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(employee, tokenId);
        _setTokenURI(tokenId, approval.uri);

        jobToEmployerId[tokenId] = approval.employerTokenId;
        employeeToJob[employee] = tokenId;

        delete employeeToApproval[employee];
    }

    /**
     * @dev Can a given employee mint a job with
     */
    function canMintJob(string memory _uri, address _minter, uint32 _employerTokenId ) external view returns (bool){
        MintApproval memory approval = getApproval(_minter);

        return keccak256(abi.encodePacked(approval.uri)) == keccak256(abi.encodePacked(_uri))
            && approval.employerTokenId == _employerTokenId;
    }

    /**
     * @dev Get the approval for a given employee
     */
    function getApproval(address employee) public view returns (MintApproval memory) {
        return employeeToApproval[employee];
    }

    /**
     * @dev Get the approval for a given employee
     */
    function getEmployerIdFromJobId(uint256 _jobId) public view returns (uint32) {
        return jobToEmployerId[_jobId];
    }

    /**
     * @dev Get the approval for a given employee
     */
    function getJobIdFromEmployee(address _employee) public view returns (uint256) {
        return employeeToJob[_employee];
    }

    /**
     * @dev Burn a token
     */
    function burn(uint256 tokenId) external {
        require(
            _msgSender() == ownerOf(tokenId)
            || owner() == _msgSender(),
            "Only the owner can do this"
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
