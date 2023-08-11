// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "popp-interfaces/IEmployerSft.sol";
import "popp-interfaces/IEmployeeNft.sol";

/**
 * @title EmployeeNft
 * @notice This contract represents an employee badge.
 It is minted by an employer and assigned to an employee as proof of their position in the organization.
 * @dev This contract is an ERC721 token that is minted by an admin or verified POPP employer and assigned to a new employee.
 * Desired Features
 * - Mint a new employee badge for any employer (admin)
 * - Mint a new employee badge for my employer (employee)
 * - Burn Tokens
 * - ERC721 full interface (base, metadata, enumerable)
 */
contract EmployeeNft is
ERC721Upgradeable,
ERC721URIStorageUpgradeable,
OwnableUpgradeable,
UUPSUpgradeable
{
    //////////////
    // Errors  //
    ////////////
    error MissingEmployerNft();
    error NonTransferable();
    //////////////////////
    // State Variables //
    ////////////////////
    uint256 private _tokenIdCounter;
    IEmployerSft private employerSft;
    mapping(address => mapping(uint32 => uint256)) private employeeToJobIds;
    mapping(uint256 => string) private tokenIdToEmployerKey;
    mapping(uint256  => string) private burnedTokenIdToURI;
    /////////////
    // Events //
    ///////////
    event NewNftMinted(uint256 _tokenId, address _to, string _tokenURI, string _employerKey);
    event TokenBurned(uint256 _tokenId, address _burnedBy);
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
    * @dev Mint a new job NFT. This handles the minting pre-existing and new jobs.
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
        string memory _employerKey = employerSft.employerKeyFromWallet(msg.sender);
        if (bytes(_employerKey).length == 0) {
            revert MissingEmployerNft();
        }

        return _mintFor(_employee, _tokenURI, _employerKey);
    }

    /**
    * @dev Mint a new job NFT. This handles the minting pre-existing and new jobs.
    * This is only callable by the admin
    *
    * @param _employee The address to mint the NFT to
    * @param _tokenURI the uir of the token metadata
    * @param _employerKey the id of the employer who minted the token
    *
    * @return uint256 representing the newly minted token id
    */
    function adminMintFor(
        address _employee,
        string memory _tokenURI,
        string memory _employerKey
    ) public onlyOwner returns (uint256) {
        return _mintFor(_employee, _tokenURI, _employerKey);
    }

    /**
    * @dev Return the mapping of employer to token id
    *E
    * @param _tokenId The id of the job nft
    * @return the employer id of the employer who minted the token
    */
    function getEmployerKey(uint256 _tokenId) public view returns (string memory) {
        return tokenIdToEmployerKey[_tokenId];
    }

    /**
     * @dev Burn a token
     * @param tokenId The token to burn
     */
    function burn(uint256 tokenId) external {
        address _sender = _msgSender();
        require(
            _msgSender() == ownerOf(tokenId)
            || owner() == _sender
            || keccak256(bytes(employerSft.employerKeyFromWallet(_sender))) == keccak256(bytes(getEmployerKey(tokenId))),
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
        string memory _employerKey
    ) internal returns (uint256) {
        _tokenIdCounter++;
        _safeMint(_to, _tokenIdCounter);
        _setTokenURI(_tokenIdCounter, _tokenURI);
        tokenIdToEmployerKey[_tokenIdCounter] = _employerKey;
        emit NewNftMinted(_tokenIdCounter, _to, _tokenURI, _employerKey);

        return _tokenIdCounter;
    }

    /**
    * @dev Override the base transfer function to only allow transfers from and to the zero address
    * @param from The address to transfer from
    * @param to The address to transfer to
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256
    ) internal virtual override(ERC721Upgradeable) {
        if (from != address(0) && to != address(0)) {
            revert NonTransferable();
        }
    }

    /**
     * @dev Override the base URI function to return the base URI for the token. We'll use ipfs here
     */
    function _baseURI() internal view virtual override(ERC721Upgradeable) returns (string memory) {
        return "ipfs://";
    }

    /**
     * @dev Override the base upgrade function to prevent upgrades from non-owner
     */
    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    /**
     * @dev Override the base tokenURI function to return the token URI for the token. We'll use ipfs here
     * @notice We keep track of all burned tokens on chain to show employment history
     */
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

    /**
     * @dev Override the base supportsInterface function to return the interface support of the contract
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override the base burn function to keep track of burned tokens.
     This to keep employment history
     */
    function _burn(uint256 tokenId)
    internal
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        burnedTokenIdToURI[tokenId] = tokenURI(tokenId);
        ERC721Upgradeable._burn(tokenId);
        emit TokenBurned(tokenId, _msgSender());
    }
}
