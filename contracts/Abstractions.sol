// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.28;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error MaxSupplyExceeded();
error PublicSaleClosed();
error TransfersLocked();
error NotAllowedByRegistry();
error RegistryNotSet();
error WrongWeiSent();
error MaxFeeExceeded();
error InputLengthsMismatch();
error InvalidMerkleProof();

interface IRegistry {
    function isAllowedOperator(address operator) external view returns (bool);
}

contract Abstractions is Ownable, OperatorFilterer, ERC2981, ERC721A {

    using BitMaps for BitMaps.BitMap;
    uint256 public maxSupply = 1513;
    bool public operatorFilteringEnabled = true;
    bool public initialTransferLockOn = true;
    bool public isRegistryActive;
    address public registryAddress;
    string private _baseTokenURI = "";

    
    // 1 variables
    uint256 public startTimePhase1 = 1738173600;
    uint256 public endTimePhase1 = 1738180800;
    uint256 public maxSupplyPhase1 = 913;
    uint256 public totalSupplyPhase1;
    uint256 public pricePhase1 = 29000000000000000;
    uint256 public maxPerWalletPhase1 = 3;
    bytes32 public merkleRootPhase1 = 0x88034c20f625c469d5ce7a9550602fe0a6dbd2a1dfa36b8d3dc1f34ea1af3029;
    mapping(address => uint256) public walletMintsPhase1;
    
    // 2 variables
    uint256 public startTimePhase2 = 1738180800;
    uint256 public endTimePhase2 = 1738184400;
    uint256 public maxSupplyPhase2 = 0;
    uint256 public totalSupplyPhase2;
    uint256 public pricePhase2 = 29000000000000000;
    uint256 public maxPerWalletPhase2 = 3;
    bytes32 public merkleRootPhase2 = 0x0;
    mapping(address => uint256) public walletMintsPhase2;
    

    constructor() ERC721A("Abstractions", "ABSX") Ownable() {

        // Register operator filtering
        _registerForOperatorFiltering();

        // Set initial 2% royalty
        _setDefaultRoyalty(owner(), 250);

    }

    // 1 Mint
    function mintPhase1(bytes32[] calldata merkleProof, uint256 quantity) external payable {

        // Check if mint has started
        if (startTimePhase1 != 0 && block.timestamp < startTimePhase1) {
            revert PublicSaleClosed();
        }

        // Check if mint has ended
        if (endTimePhase1 != 0 && block.timestamp > endTimePhase1) {
            revert PublicSaleClosed();
        }

        // Check if the mint will exceed total max supply, if set.
        if (maxSupply > 0 && totalSupply() + quantity > maxSupply) {
            revert MaxSupplyExceeded();
        }

        // If phase max supply is set, check if it's exceeded
        if (maxSupplyPhase1 != 0 && totalSupplyPhase1 + quantity > maxSupplyPhase1) {
            revert MaxSupplyExceeded();
        }

        // Check if the price is correct
        if (msg.value != (pricePhase1 * quantity)) {
            revert WrongWeiSent();
        }
        
        // Check if the proof is set, and if it is valid
        if (merkleRootPhase1 != bytes32(0)) {
            // Using Merkle Tree
            bytes32 node = keccak256(abi.encodePacked(msg.sender, quantity));
            if (!MerkleProof.verify(merkleProof, merkleRootPhase1, node)) {
                revert InvalidMerkleProof();
            }
        }
            
        // If allowlist is not set, check if we have exceeded phase max per wallet if set.
        else if (maxPerWalletPhase1 > 0 && walletMintsPhase1[msg.sender] + quantity > maxPerWalletPhase1) {
            revert MaxSupplyExceeded();
        }

        // Mint the tokens
        totalSupplyPhase1 += quantity;
        _mint(msg.sender, quantity);

    }

    // 2 Mint
    function mintPhase2(uint256 quantity) external payable {

        // Check if mint has started
        if (startTimePhase2 != 0 && block.timestamp < startTimePhase2) {
            revert PublicSaleClosed();
        }

        // Check if mint has ended
        if (endTimePhase2 != 0 && block.timestamp > endTimePhase2) {
            revert PublicSaleClosed();
        }

        // Check if the mint will exceed total max supply, if set.
        if (maxSupply > 0 && totalSupply() + quantity > maxSupply) {
            revert MaxSupplyExceeded();
        }

        // If phase max supply is set, check if it's exceeded
        if (maxSupplyPhase2 != 0 && totalSupplyPhase2 + quantity > maxSupplyPhase2) {
            revert MaxSupplyExceeded();
        }

        // Check if the price is correct
        if (msg.value != (pricePhase2 * quantity)) {
            revert WrongWeiSent();
        }
        
        // If allowlist is not set, check if we have exceeded phase max per wallet if set.
        else if (maxPerWalletPhase2 > 0 && walletMintsPhase2[msg.sender] + quantity > maxPerWalletPhase2) {
            revert MaxSupplyExceeded();
        }

        // Mint the tokens
        totalSupplyPhase2 += quantity;
        _mint(msg.sender, quantity);

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
    function ownerMint(address to, uint256 quantity) external onlyOwner {
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
            revert("Transfer failed.");
        }
    }

    // Withdraw Balance to Address
    function withdrawTo(address payable _to) public onlyOwner {
        (bool success, ) = payable(_to).call{value: address(this).balance}("");
        if (!success) {
            revert("Transfer failed.");
        }
    }

    // Break Transfer Lock
    function breakLock() external onlyOwner {
        initialTransferLockOn = false;
    }

    // Set the start time for the phase
    function setStartTimePhase1(uint256 newStartTime) external onlyOwner {
        startTimePhase1 = newStartTime;
    }

    // Set the end time for the phase
    function setEndTime1(uint256 newEndTime) external onlyOwner {
        endTimePhase1 = newEndTime;
    }

    // Set the max supply for the phase
    function setMaxSupplyPhase1(uint256 newMaxSupply) external onlyOwner {
        maxSupplyPhase1 = newMaxSupply;
    }

    // Set max per wallet for the phase
    function setMaxPerWalletPhase1(uint256 newMaxPerWallet) external onlyOwner {
        maxPerWalletPhase1 = newMaxPerWallet;
    }

    // Set the price for the phase
    function setPricePhase1(uint256 newPrice) external onlyOwner {
        pricePhase1 = newPrice;
    }

    // Set the merkle root for the phase
    function setMerkleRootPhase1(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootPhase1 = newMerkleRoot;
    }// Set the start time for the phase
    function setStartTimePhase2(uint256 newStartTime) external onlyOwner {
        startTimePhase2 = newStartTime;
    }

    // Set the end time for the phase
    function setEndTime2(uint256 newEndTime) external onlyOwner {
        endTimePhase2 = newEndTime;
    }

    // Set the max supply for the phase
    function setMaxSupplyPhase2(uint256 newMaxSupply) external onlyOwner {
        maxSupplyPhase2 = newMaxSupply;
    }

    // Set max per wallet for the phase
    function setMaxPerWalletPhase2(uint256 newMaxPerWallet) external onlyOwner {
        maxPerWalletPhase2 = newMaxPerWallet;
    }

    // Set the price for the phase
    function setPricePhase2(uint256 newPrice) external onlyOwner {
        pricePhase2 = newPrice;
    }

    // Set the merkle root for the phase
    function setMerkleRootPhase2(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootPhase2 = newMerkleRoot;
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
        onlyAllowedOperatorApproval(operator)
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
        onlyAllowedOperatorApproval(operator)
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
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
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
        if (_isValidAgainstRegistry(msg.sender)) {
            super._beforeTokenTransfers(from, to, startTokenId, quantity);
        } else {
            revert NotAllowedByRegistry();
        }
    }

    function _isValidAgainstRegistry(address operator)
        internal
        view
        returns (bool)
    {
        if (isRegistryActive) {
            IRegistry registry = IRegistry(registryAddress);
            return registry.isAllowedOperator(operator);
        }
        return true;
    }

    function setIsRegistryActive(bool _isRegistryActive) external onlyOwner {
        if (registryAddress == address(0)) revert RegistryNotSet();
        isRegistryActive = _isRegistryActive;
    }

    function setRegistryAddress(address _registryAddress) external onlyOwner {
        registryAddress = _registryAddress;
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

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "/", _toString(tokenId), ".json")) : "";

    }

}