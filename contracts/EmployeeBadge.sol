// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

// Desired Features
// - Approve minting of new job NFTs done by the employer
// - Mint new job NFTs
// - Check if a given wallet can mint a job NFT
// - Burn Tokens
// - ERC721 full interface (base, metadata, enumerable)
// - Calculate the price and pay the fee to mint a new job NFT in $POPP ERC-20
contract EmployeeBadge is
ERC721,
ERC721URIStorage,
Ownable
{
    string private baseURI = "";
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    mapping(address => mapping(uint32 => uint256)) private employeeToJobIds;
    mapping(uint256 => uint32) private jobToEmployerId;

    constructor() ERC721("Proof Of Position Alpha 0.1", "POPP_0.1") { }

    /**
    * @dev Mint a new job NFT. This is done when onboarding a new employee.
    * @param _employee The address of the employee
    * @param _employerId The ID of the employer of this job
    * @param _uri The uri of the job badge nft
    */
    function mint(
        address _employee,
        uint32 _employerId,
        string memory _uri
    ) external onlyOwner {

        if (employeeToJobIds[_employee][_employerId] != 0) {
            // If the employee already has a job NFT for this employer, burn it
            _burn(employeeToJobIds[_employee][_employerId]);
        }

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(_employee, tokenId);
        _setTokenURI(tokenId, _uri);

        jobToEmployerId[tokenId] = _employerId;
        employeeToJobIds[_employee][_employerId] = tokenId;
    }

    /**
     * @dev Burn a token
     * @param tokenId The token to burn
     */
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256
    ) internal virtual override(ERC721) {
        require(from == address(0) || to == address(0), "POPP is non-transferable");
    }

    function _burn(uint256 tokenId)
    internal
    override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return baseURI;
    }

    /**
    * @dev Sets `baseURI` as the `_baseURI` for all tokens
     */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
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
    override(ERC721, ERC721URIStorage)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {}

    fallback() external payable {}

    function selfDestruct() public onlyOwner {
        selfdestruct(payable(owner()));
    }
}
