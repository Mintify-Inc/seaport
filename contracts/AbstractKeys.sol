// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.28;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error MaxSupplyExceeded();
error PhaseMaxSupplyExceeded();
error MaxPerWalletExceeded();
error MaxPerOrderExceeded();
error PhaseClosed();
error TransfersLocked();
error NotAllowedByRegistry();
error RegistryNotSet();
error WrongWeiSent();
error MaxFeeExceeded();
error InputLengthsMismatch();
error InvalidMerkleProof();
error InvalidAmount();
error InvalidAddress();

interface IRegistry {
    function isAllowedOperator(address operator) external view returns (bool);
}

contract MintifyAbstractKeys is ReentrancyGuard, Ownable, OperatorFilterer, ERC2981, ERC721A {
    using BitMaps for BitMaps.BitMap;

    // Phases status
    bool public phaseOneOpen;
    bool public phaseTwoOpen;

    // Phases prices
    uint256 public phaseOnePrice = 6000000000000000; // 0.006 ETH
    uint256 public phaseTwoPrice = 9500000000000000; // 0.0095 ETH

    // Phases maps
    mapping(address => uint256) public phaseOneAllowance;
    mapping(address => uint256) public phaseTwoAllowance;

    // Phases supply limits
    uint256 public phaseOneSupply;
    uint256 public phaseOneSupplyLimit = 5800;
    uint256 public phaseOneMaxPerWallet = 3;
    uint256 public phaseTwoSupply;
    uint256 public phaseTwoSupplyLimit; // No limit
    uint256 public phaseTwoMaxPerWallet = 5;

    // Phases Merkle Roots
    bytes32 public phaseOneMerkleRoot = 0xdd9f5a34108c0bcaa6a6937c38d0dc131b5b45fe424ebe2706e6e48d4aa1d0fd;

    uint256 public maxSupply = 12000;

    bool public operatorFilteringEnabled = true;
    bool public initialTransferLockOn = true;
    bool public isRegistryActive;
    address public registryAddress;

    // Events
    event PhaseOneStatusChanged(bool newState);
    event PhaseTwoStatusChanged(bool newState);
    event PhaseOneMerkleRootUpdated(bytes32 newMerkleRoot);
    event MaxSupplyUpdated(uint256 newMaxSupply);
    event MaxPerWalletUpdated(uint256 newMaxPerWallet);
    event MaxPerOrderUpdated(uint256 newMaxPerOrder);
    event PhaseOnePriceUpdated(uint256 newPrice);
    event PhaseTwoPriceUpdated(uint256 newPrice);
    event PhaseOneSupplyLimitUpdated(uint256 newSupplyLimit);
    event PhaseTwoSupplyLimitUpdated(uint256 newSupplyLimit);

    string public _baseTokenURI = "https://genesis-metas.mintify.xyz";

    constructor() ERC721A("Mintify Abstract Keys", "MNFABK") Ownable() {

        // Register operator filtering
        _registerForOperatorFiltering();

        // Set initial 2% royalty
        _setDefaultRoyalty(owner(), 200);

    }

    // Phase 1 Mint
    function phaseOneMint(uint256 quantity, bytes32[] calldata merkleProof) external payable nonReentrant {
        
        // Check if phase is open
        if (!phaseOneOpen) {
            revert PhaseClosed();
        }

        // Verify merkle proof
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(merkleProof, phaseOneMerkleRoot, node)) {
            revert InvalidMerkleProof();
        }

        // Check if quantity is within limits
        if (phaseOneAllowance[msg.sender] + quantity > phaseOneMaxPerWallet) {
            revert MaxPerWalletExceeded();
        }

        // Check if phase supply is within limits
        if (phaseOneSupply != 0 && phaseOneSupply + quantity > phaseOneSupplyLimit) {
            revert PhaseMaxSupplyExceeded();
        }

        // Check if total supply is within limits
        if (maxSupply != 0 && totalSupply() + quantity > maxSupply) {
            revert MaxSupplyExceeded();
        }

        // Check if price sent is correct
        if (msg.value != (phaseOnePrice * quantity)) {
            revert WrongWeiSent();
        }

        // Add to users allowance ledger
        phaseOneAllowance[msg.sender] += quantity;

        // Add to phase supply
        phaseOneSupply += quantity;

        // Mint
         _mint(msg.sender, quantity);

    }

    // Phase 2 Mint
    function phaseTwoMint(uint256 quantity) external payable nonReentrant {
        
        // Check if phase is open
        if (!phaseTwoOpen) {
            revert PhaseClosed();
        }

        // Check total minted across both phases
        if (phaseTwoMaxPerWallet != 0 && phaseTwoAllowance[msg.sender] + quantity > phaseTwoMaxPerWallet) {
            revert MaxPerWalletExceeded();
        }

        // Check if phase supply is within limits
        if (phaseTwoSupply != 0 && phaseTwoSupply + quantity > phaseTwoSupplyLimit) {
            revert PhaseMaxSupplyExceeded();
        }

        // Check if total supply is within limits
        if (maxSupply != 0 && totalSupply() + quantity > maxSupply) {
            revert MaxSupplyExceeded();
        }

        // Check if price sent is correct
        if (msg.value != (phaseTwoPrice * quantity)) {
            revert WrongWeiSent();
        }

        // Add to users allowance ledger
        phaseTwoAllowance[msg.sender] += quantity;

        // Add to phase supply
        phaseTwoSupply += quantity;

        // Mint
         _mint(msg.sender, quantity);

    }


    // =========================================================================
    //                           Owner Only Functions
    // =========================================================================

    // Owner airdrop
    function airDrop(address[] memory users, uint256[] memory amounts) external onlyOwner nonReentrant {
        // iterate over users and amounts
        if (users.length != amounts.length) {
            revert InputLengthsMismatch();
        }
        for (uint256 i; i < users.length;) {

            // Check for zero amounts
            if (amounts[i] == 0) {
                revert InvalidAmount();
            }

            // Check for zero address
            if (users[i] == address(0)) {
                revert InvalidAddress();
            }

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
    function ownerMint(address to, uint256 quantity) external onlyOwner nonReentrant {

        // Check for zero address
        if (to == address(0)) {
            revert InvalidAddress();
        }

        if (maxSupply != 0 && totalSupply() + quantity > maxSupply) {
            revert MaxSupplyExceeded();
        }
        _mint(to, quantity);
    }

    // Enables or disables phase 1
    function setPhaseOneStatus(bool newState) external onlyOwner {
        phaseOneOpen = newState;
        emit PhaseOneStatusChanged(newState);
    }

    // Enables or disables phase 2
    function setPhaseTwoStatus(bool newState) external onlyOwner {
        phaseTwoOpen = newState;
        emit PhaseTwoStatusChanged(newState);
    }

    // Set phase one merkle root
    function setPhaseOneMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        phaseOneMerkleRoot = _merkleRoot;
        emit PhaseOneMerkleRootUpdated(_merkleRoot);
    }

    // Set phase 1 price
    function setPhaseOnePrice(uint256 newPrice) external onlyOwner {
        phaseOnePrice = newPrice;
        emit PhaseOnePriceUpdated(newPrice);
    }

    // Set phase 2 price
    function setPhaseTwoPrice(uint256 newPrice) external onlyOwner {
        phaseTwoPrice = newPrice;
        emit PhaseTwoPriceUpdated(newPrice);
    }

    // Set phase one supply limit
    function setPhaseOneSupplyLimit(uint256 newSupplyLimit) external onlyOwner {
        phaseOneSupplyLimit = newSupplyLimit;
        emit PhaseOneSupplyLimitUpdated(newSupplyLimit);
    }

    // Set phase two supply limit
    function setPhaseTwoSupplyLimit(uint256 newSupplyLimit) external onlyOwner {
        phaseTwoSupplyLimit = newSupplyLimit;
        emit PhaseTwoSupplyLimitUpdated(newSupplyLimit);
    }

    // Set phase one max per wallet
    function setPhaseOneMaxPerWallet(uint256 newMaxPerWallet) external onlyOwner {
        phaseOneMaxPerWallet = newMaxPerWallet;
        emit MaxPerWalletUpdated(newMaxPerWallet);
    }

    // Set phase two max per wallet
    function setPhaseTwoMaxPerWallet(uint256 newMaxPerWallet) external onlyOwner {
        phaseTwoMaxPerWallet = newMaxPerWallet;
        emit MaxPerWalletUpdated(newMaxPerWallet);
    }

    // Set max supply
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
        emit MaxSupplyUpdated(newMaxSupply);
    }

    // Withdraw Balance to owner
    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        if (!success) {
            revert();
        }
    }

    // Withdraw Balance to Address
    function withdrawTo(address payable _to) public onlyOwner nonReentrant {

        // Check for zero address
        if (_to == address(0)) {
            revert InvalidAddress();
        }

        (bool success, ) = payable(_to).call{value: address(this).balance}("");
        if (!success) {
            revert();
        }
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
        // Supports the following `interfaceId`s:
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
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "/abstract/", _toString(tokenId))) : "";

    }

}