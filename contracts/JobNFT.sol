// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Desired Features
// - Approve minting of new job NFTs done by the employer
// - Mint new job NFTs
// - Check if a given wallet can mint a job NFT
// - Burn Tokens
// - ERC721 full interface (base, metadata, enumerable)
contract JobNFT is
ERC721,
ERC721URIStorage,
Ownable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    mapping(address => MintApproval) employeeToApproval;

    struct MintApproval {
        string uri;
        address employer;
    }

    constructor() ERC721("Proof Of Position", "POPP") {}

    /**
     * @dev Create approval for an employee to mint a POPP
     */
    function approveMint(
        address employee,
        string memory uri
    ) public {
        MintApproval memory approval = MintApproval(
            uri,
            _msgSender()
        );
        employeeToApproval[employee] = approval;
    }

    /**
     * @dev Mint a new POPP
     * @return uint256 representing the newly minted token id
     */
    function mintItem(address employee) public {
        MintApproval memory approval = getApproval(employee);
        require(approval.employer != address(0), "you don't have approval to mint this NFT");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(employee, tokenId);
        _setTokenURI(tokenId, approval.uri);
        delete employeeToApproval[_msgSender()];
    }

    /**
     * @dev Get the approval for a given employee
     */
    function canMintJob(string memory uri, address minter) external view returns (bool){
        MintApproval memory approval = getApproval(minter);
        
        return keccak256(abi.encodePacked(approval.uri)) == keccak256(abi.encodePacked(uri));
    }

    /**
     * @dev Get the approval for a given employee
     */
    function getApproval(address employee) public view returns (MintApproval memory) {
        return employeeToApproval[employee];
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

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal pure override(ERC721) {
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
    override(ERC721)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
