// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "popp-interfaces/IEmployerSft.sol";
import "popp-interfaces/IEmployeeNft.sol";

// Desired Features
// - Mint NFTs as an employer
// - Mint NFTs as an admin
// - Burn Tokens
// - ERC721 full interface (baseURI, metadata, enumerable)
contract EmployeeBadge is
ERC721Upgradeable,
ERC721URIStorageUpgradeable,
OwnableUpgradeable,
UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    IEmployerSft private employerSft;
    mapping(address => mapping(uint32 => uint256)) private employeeToJobIds;
    mapping(uint256 => uint32) private tokenIdToEmployerId;
    mapping(uint256  => string) private burnedTokenIdToURI;
    /**
         * @dev We use the employer NFT contract to map the msg.sender to the employer id
     */
    function initialize(
        address _employerSftAddress
    ) initializer public {
        __ERC721_init("Proof Of Position", "POPP");
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        employerSft = IEmployerSft(_employerSftAddress);
    }

    /**
    * @dev Mint a new job NFT. This handles the minting pre-existing and new jobs.@author
    * An employer must hold a employer badge to mint
    *
    * @param _employee The address to mint the NFT to
    * @param _tokenURI the uir of the token metadata
    *
    * @return uint256 representing the newly minted token id
    */
    function mintFor(
        address _employee,
        string memory _tokenURI
    ) external returns (uint256) {
        uint32 _employerId = employerSft.employerIdFromWallet(msg.sender);
        require(_employerId != 0, "You need to be a POPP verified employer to do this.");

        return _mintFor(_employee, _tokenURI, _employerId);
    }

    /**
    * @dev Mint a new job NFT. This handles the minting pre-existing and new jobs.
    * This is only callable by the admin
    *
    * @param _employee The address to mint the NFT to
    * @param _tokenURI the uir of the token metadata
    * @param _employerId the id of the employer who minted the token
    *
    * @return uint256 representing the newly minted token id
    */
    function adminMintFor(
        address _employee,
        string memory _tokenURI,
        uint32 _employerId
    ) public onlyOwner returns (uint256) {
        return _mintFor(_employee, _tokenURI, _employerId);
    }

    /**
    * @dev Return the mapping of employer to token id
    *
    * @param _tokenId The id of the job nft
    * @return the employer id of the employer who minted the token
    */
    function getEmployerId(uint256 _tokenId) public view returns (uint32) {
        return tokenIdToEmployerId[_tokenId];
    }

    /**
     * @dev Burn a token
     * @param tokenId The token to burn
     */
    function burn(uint256 tokenId) external {
        uint32 _employerId = getEmployerId(tokenId);
        address _sender = _msgSender();
        require(
            _msgSender() == ownerOf(tokenId)
            || owner() == _sender
            || employerSft.employerIdFromWallet(_sender) == _employerId,
            "Only the employee or employer can do this"
        );
        _burn(tokenId);
    }

    /**
     * @dev Mint a new token
     *
     * @return uint256 representing the newly minted token id
     */
    function _mintFor(
        address _to,
        string memory _tokenURI,
        uint32 _employerId
    ) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 _tokenId = _tokenIdCounter.current();

        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        tokenIdToEmployerId[_tokenId] = _employerId;

        return _tokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256
    ) internal virtual override(ERC721Upgradeable) {
        require(from == address(0) || to == address(0), "POPP is non-transferable");
    }

    function _baseURI() internal view virtual override(ERC721Upgradeable) returns (string memory) {
        return "ipfs://";
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
    {
        // we need to keep metadata on chain for burned token to show employment history
        if (bytes(burnedTokenIdToURI[tokenId]).length > 0) {
            return burnedTokenIdToURI[tokenId];
        }

        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
    internal
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        burnedTokenIdToURI[tokenId] = tokenURI(tokenId);
        ERC721Upgradeable._burn(tokenId);
    }
}
