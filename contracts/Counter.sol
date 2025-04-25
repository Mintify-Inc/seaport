// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.28;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

error MaxSupplyExceeded();
error PublicSaleClosed();
error TransfersLocked();
error NotAllowedByRegistry();
error RegistryNotSet();
error WrongWeiSent();
error MaxFeeExceeded();
error InputLengthsMismatch();
error InvalidMerkleProof();
error InvalidLaunchpadFee();
error InvalidLaunchpadFeeAddress();
error TransferFailed();

interface IRegistry {
    function isAllowedOperator(address operator) external view returns (bool);
}

contract Counter is Ownable, ERC2981, ERC721A {

    // Launchpad Fee
    uint256 public launchpadFee = 370000000000000;
    uint256 public launchpadCutBps = 500;
    address public launchpadFeeAddress = 0x2DCC7c4Ab800bF67380e2553BE1E6891A36F18E7;
    event LaunchpadFeeSent(address indexed feeAddress, uint256 feeAmount);

    using BitMaps for BitMaps.BitMap;
    uint256 public maxSupply = 0;
    bool public operatorFilteringEnabled = true;
    bool public initialTransferLockOn = true;
    bool public isRegistryActive;
    address public registryAddress;
    string private _baseTokenURI = "";
    string private _placeHolderTokenURI = "";
    

    constructor() ERC721A("Counter", "USD") Ownable() {
        

    }
    

    // =========================================================================
    //                           Owner Only Functions
    // =========================================================================

    // Owner airdrop
    function airDrop(address[] memory users, uint256[] memory amounts) external onlyOwner {

        // iterate over users and amounts
        if (users.length != amounts.length) {
            revert InputLengthsMismatch();
        }
        for (uint256 i; i < users.length;) {
            if (maxSupply != 0 && totalSupply() + amounts[i] > maxSupply) {
                revert MaxSupplyExceeded();
            }
            _mint(users[i], amounts[i]);
            unchecked {
                ++i;
            }
        }

    }

    // Owner unrestricted mint
    function ownerMint(address to, uint256 quantity) external {
        if (maxSupply != 0 && totalSupply() + quantity > maxSupply) {
            revert MaxSupplyExceeded();
        }
        _mint(to, quantity);
    }

    // Set max supply
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    // Withdraw Balance to owner
    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    // Withdraw Balance to Address
    function withdrawTo(address payable _to) public onlyOwner {
        (bool success, ) = payable(_to).call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    // Send Launchpad Flat Fee
    function _sendLaunchpadFee(uint256 feeAmount) private {
        if (feeAmount == 0) {
            revert InvalidLaunchpadFee();
        }
        if (launchpadFeeAddress == address(0)) {
            revert InvalidLaunchpadFeeAddress();
        }
        (bool success, ) = payable(launchpadFeeAddress).call{value: feeAmount}("");
        if (!success) {
            revert TransferFailed();
        }
        emit LaunchpadFeeSent(launchpadFeeAddress, feeAmount);
    }

    // Break Transfer Lock
    function breakLock() external onlyOwner {
        initialTransferLockOn = false;
    }

    // =========================================================================
    //                             ERC721A Misc
    // =========================================================================

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override (ERC721A)
    {
        if (initialTransferLockOn) {
            revert TransfersLocked();
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (ERC721A)
    {
        if (initialTransferLockOn) {
            revert TransfersLocked();
        }
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (ERC721A)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =========================================================================
    //                             Registry Check
    // =========================================================================
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (initialTransferLockOn && from != address(0) && to != address(0)) {
            revert TransfersLocked();
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    // =========================================================================
    //                                  ERC165
    // =========================================================================

    function supportsInterface(bytes4 interfaceId) public view override (ERC721A, ERC2981) returns (bool) {
        // Supports the following interfaceIds:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                                 ERC2891
    // =========================================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        if (feeNumerator > 1000) {
            revert MaxFeeExceeded();
        }
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        if (feeNumerator > 1000) {
            revert MaxFeeExceeded();
        }
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    // =========================================================================
    //                                 Metadata
    // =========================================================================

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPlaceholderBaseURI(string calldata placeholderURI) external onlyOwner {
        _placeHolderTokenURI = placeholderURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _placeHolderURI() internal view returns (string memory) {
        return _placeHolderTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        string memory placeHolderURI = _placeHolderURI();
        if (bytes(baseURI).length != 0) {
            return string(abi.encodePacked(baseURI, "/", _toString(tokenId), ".json"));
        }
        if (bytes(placeHolderURI).length != 0) {
            return placeHolderURI;
        }
        return "";

    }

}