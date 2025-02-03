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
error InvalidLaunchpadFee();
error InvalidLaunchpadFeeAddress();
error TransferFailed();

interface IRegistry {
    function isAllowedOperator(address operator) external view returns (bool);
}

contract ToadsInTheTrenches is Ownable, OperatorFilterer, ERC2981, ERC721A {

    // Launchpad Fee
    uint256 public launchpadFee = 370000000000000;
    address public launchpadFeeAddress = 0x2DCC7c4Ab800bF67380e2553BE1E6891A36F18E7;

    using BitMaps for BitMaps.BitMap;
    uint256 public maxSupply = 3333;
    bool public operatorFilteringEnabled = true;
    bool public initialTransferLockOn = true;
    bool public isRegistryActive;
    address public registryAddress;
    string private _baseTokenURI = "";

    
    // Phase 1 variables
    uint256 public startTimePhase1 = 1738688400;
    uint256 public endTimePhase1 = 1738692000;
    uint256 public maxSupplyPhase1 = 0;
    uint256 public totalSupplyPhase1;
    uint256 public pricePhase1 = 0;
    uint256 public maxPerWalletPhase1 = 3;
    bytes32 public merkleRootPhase1 = 0xb84c78161c34e0f3149d835f77d390462f27e6a8e5346985f8703ac88f020461;
    mapping(address => uint256) public walletMintsPhase1;
    
    // Phase 2 variables
    uint256 public startTimePhase2 = 1738692000;
    uint256 public endTimePhase2 = 1738699200;
    uint256 public maxSupplyPhase2 = 0;
    uint256 public totalSupplyPhase2;
    uint256 public pricePhase2 = 0;
    uint256 public maxPerWalletPhase2 = 2;
    bytes32 public merkleRootPhase2 = 0x7d280ae2377d7556e7905b1995a8f24cf0887e18f4f1c70b75ccfe33fb520156;
    mapping(address => uint256) public walletMintsPhase2;
    
    // Phase 3 variables
    uint256 public startTimePhase3 = 1738699200;
    uint256 public endTimePhase3 = 1738702800;
    uint256 public maxSupplyPhase3 = 0;
    uint256 public totalSupplyPhase3;
    uint256 public pricePhase3 = 0;
    uint256 public maxPerWalletPhase3 = 2;
    bytes32 public merkleRootPhase3 = 0x7d280ae2377d7556e7905b1995a8f24cf0887e18f4f1c70b75ccfe33fb520156;
    mapping(address => uint256) public walletMintsPhase3;
    
    // Phase 4 variables
    uint256 public startTimePhase4 = 1738702800;
    uint256 public endTimePhase4 = 1738706400;
    uint256 public maxSupplyPhase4 = 0;
    uint256 public totalSupplyPhase4;
    uint256 public pricePhase4 = 0;
    uint256 public maxPerWalletPhase4 = 5;
    bytes32 public merkleRootPhase4 = 0x0;
    mapping(address => uint256) public walletMintsPhase4;
    

    constructor() ERC721A("ToadsInTheTrenches", "TNT") Ownable() {

        // Register operator filtering
        _registerForOperatorFiltering();

        // Set initial royalty
        _setDefaultRoyalty(owner(), 500);
        
        // Deployment Airdrop
        _mint(0xb1D6db878321acCF2A8Bf482750B3A4eFD9c5Cd4, 350);

    }

    // Phase 1 Mint
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
        if (msg.value != (pricePhase1 + launchpadFee) * quantity) {
            revert WrongWeiSent();
        }
         

        // Check if the proof is set, and if it is valid
        if (merkleRootPhase1 != bytes32(0)) {
            // Using Merkle Tree
            bytes32 node = keccak256(abi.encodePacked(msg.sender));
            if (!MerkleProof.verify(merkleProof, merkleRootPhase1, node)) {
                revert InvalidMerkleProof();
            }
        }
            
        // Check if we have exceeded phase max per wallet if set.
        if (maxPerWalletPhase1 > 0 && walletMintsPhase1[msg.sender] + quantity > maxPerWalletPhase1) {
            revert MaxSupplyExceeded();
        }

        // Send the Launchpad Fee if set
        if (launchpadFee > 0 && launchpadFeeAddress != address(0)) {
            uint256 feeAmount = launchpadFee * quantity;
            sendLaunchpadFee(feeAmount);
        }

        // Mint the tokens
        walletMintsPhase1[msg.sender] += quantity;
        totalSupplyPhase1 += quantity;
        _mint(msg.sender, quantity);

    }

    // Phase 2 Mint
    function mintPhase2(bytes32[] calldata merkleProof, uint256 quantity) external payable {

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
        if (msg.value != (pricePhase2 + launchpadFee) * quantity) {
            revert WrongWeiSent();
        }
         

        // Check if the proof is set, and if it is valid
        if (merkleRootPhase2 != bytes32(0)) {
            // Using Merkle Tree
            bytes32 node = keccak256(abi.encodePacked(msg.sender));
            if (!MerkleProof.verify(merkleProof, merkleRootPhase2, node)) {
                revert InvalidMerkleProof();
            }
        }
            
        // Check if we have exceeded phase max per wallet if set.
        if (maxPerWalletPhase2 > 0 && walletMintsPhase2[msg.sender] + quantity > maxPerWalletPhase2) {
            revert MaxSupplyExceeded();
        }

        // Send the Launchpad Fee if set
        if (launchpadFee > 0 && launchpadFeeAddress != address(0)) {
            uint256 feeAmount = launchpadFee * quantity;
            sendLaunchpadFee(feeAmount);
        }

        // Mint the tokens
        walletMintsPhase2[msg.sender] += quantity;
        totalSupplyPhase2 += quantity;
        _mint(msg.sender, quantity);

    }

    // Phase 3 Mint
    function mintPhase3(bytes32[] calldata merkleProof, uint256 quantity) external payable {

        // Check if mint has started
        if (startTimePhase3 != 0 && block.timestamp < startTimePhase3) {
            revert PublicSaleClosed();
        }

        // Check if mint has ended
        if (endTimePhase3 != 0 && block.timestamp > endTimePhase3) {
            revert PublicSaleClosed();
        }

        // Check if the mint will exceed total max supply, if set.
        if (maxSupply > 0 && totalSupply() + quantity > maxSupply) {
            revert MaxSupplyExceeded();
        }

        // If phase max supply is set, check if it's exceeded
        if (maxSupplyPhase3 != 0 && totalSupplyPhase3 + quantity > maxSupplyPhase3) {
            revert MaxSupplyExceeded();
        }

        // Check if the price is correct
        if (msg.value != (pricePhase3 + launchpadFee) * quantity) {
            revert WrongWeiSent();
        }
         

        // Check if the proof is set, and if it is valid
        if (merkleRootPhase3 != bytes32(0)) {
            // Using Merkle Tree
            bytes32 node = keccak256(abi.encodePacked(msg.sender));
            if (!MerkleProof.verify(merkleProof, merkleRootPhase3, node)) {
                revert InvalidMerkleProof();
            }
        }
            
        // Check if we have exceeded phase max per wallet if set.
        if (maxPerWalletPhase3 > 0 && walletMintsPhase3[msg.sender] + quantity > maxPerWalletPhase3) {
            revert MaxSupplyExceeded();
        }

        // Send the Launchpad Fee if set
        if (launchpadFee > 0 && launchpadFeeAddress != address(0)) {
            uint256 feeAmount = launchpadFee * quantity;
            sendLaunchpadFee(feeAmount);
        }

        // Mint the tokens
        walletMintsPhase3[msg.sender] += quantity;
        totalSupplyPhase3 += quantity;
        _mint(msg.sender, quantity);

    }

    // Phase 4 Mint
    function mintPhase4(uint256 quantity) external payable {

        // Check if mint has started
        if (startTimePhase4 != 0 && block.timestamp < startTimePhase4) {
            revert PublicSaleClosed();
        }

        // Check if mint has ended
        if (endTimePhase4 != 0 && block.timestamp > endTimePhase4) {
            revert PublicSaleClosed();
        }

        // Check if the mint will exceed total max supply, if set.
        if (maxSupply > 0 && totalSupply() + quantity > maxSupply) {
            revert MaxSupplyExceeded();
        }

        // If phase max supply is set, check if it's exceeded
        if (maxSupplyPhase4 != 0 && totalSupplyPhase4 + quantity > maxSupplyPhase4) {
            revert MaxSupplyExceeded();
        }

        // Check if the price is correct
        if (msg.value != (pricePhase4 + launchpadFee) * quantity) {
            revert WrongWeiSent();
        }
         
        // Check if we have exceeded phase max per wallet if set.
        if (maxPerWalletPhase4 > 0 && walletMintsPhase4[msg.sender] + quantity > maxPerWalletPhase4) {
            revert MaxSupplyExceeded();
        }

        // Send the Launchpad Fee if set
        if (launchpadFee > 0 && launchpadFeeAddress != address(0)) {
            uint256 feeAmount = launchpadFee * quantity;
            sendLaunchpadFee(feeAmount);
        }

        // Mint the tokens
        walletMintsPhase4[msg.sender] += quantity;
        totalSupplyPhase4 += quantity;
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

    // Send Launchpad Fee
    function sendLaunchpadFee(uint256 feeAmount) public {
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
    function setEndTimePhase1(uint256 newEndTime) external onlyOwner {
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
    function setEndTimePhase2(uint256 newEndTime) external onlyOwner {
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
    }// Set the start time for the phase
    function setStartTimePhase3(uint256 newStartTime) external onlyOwner {
        startTimePhase3 = newStartTime;
    }

    // Set the end time for the phase
    function setEndTimePhase3(uint256 newEndTime) external onlyOwner {
        endTimePhase3 = newEndTime;
    }

    // Set the max supply for the phase
    function setMaxSupplyPhase3(uint256 newMaxSupply) external onlyOwner {
        maxSupplyPhase3 = newMaxSupply;
    }

    // Set max per wallet for the phase
    function setMaxPerWalletPhase3(uint256 newMaxPerWallet) external onlyOwner {
        maxPerWalletPhase3 = newMaxPerWallet;
    }

    // Set the price for the phase
    function setPricePhase3(uint256 newPrice) external onlyOwner {
        pricePhase3 = newPrice;
    }

    // Set the merkle root for the phase
    function setMerkleRootPhase3(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootPhase3 = newMerkleRoot;
    }// Set the start time for the phase
    function setStartTimePhase4(uint256 newStartTime) external onlyOwner {
        startTimePhase4 = newStartTime;
    }

    // Set the end time for the phase
    function setEndTimePhase4(uint256 newEndTime) external onlyOwner {
        endTimePhase4 = newEndTime;
    }

    // Set the max supply for the phase
    function setMaxSupplyPhase4(uint256 newMaxSupply) external onlyOwner {
        maxSupplyPhase4 = newMaxSupply;
    }

    // Set max per wallet for the phase
    function setMaxPerWalletPhase4(uint256 newMaxPerWallet) external onlyOwner {
        maxPerWalletPhase4 = newMaxPerWallet;
    }

    // Set the price for the phase
    function setPricePhase4(uint256 newPrice) external onlyOwner {
        pricePhase4 = newPrice;
    }

    // Set the merkle root for the phase
    function setMerkleRootPhase4(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootPhase4 = newMerkleRoot;
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