// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WorkNFT
 * @dev ERC-721 credential NFT that serves as a verifiable credential of completed work.
 * Only the owner (WorkMarketplace) can mint.
 */
contract WorkNFT is ERC721, Ownable {
    uint256 public nextTokenId = 1;

    struct WorkData {
        uint256 jobId;
        uint256 reward;      // USDC amount (informational)
        uint256 deadline;    // timestamp
        string title;
        string deliveryUrl;
    }

    mapping(uint256 tokenId => WorkData) public workInfo;

    constructor(address owner) ERC721("Work Credential", "WORKNFT") Ownable(owner) {
        // Owner will be the deployer initially.
        // After deployment, transferOwnership to WorkMarketplace.
    }

    /**
     * @dev Mint a Work Credential NFT and store the job metadata on-chain.
     * Only callable by the owner (WorkMarketplace contract).
     */
    function mintWorkNft(
        address to,
        uint256 jobId,
        uint256 reward,
        uint256 deadline,
        string memory title,
        string memory deliveryUrl
    ) external onlyOwner returns (uint256 tokenId) {
        tokenId = nextTokenId++;
        _safeMint(to, tokenId);

        workInfo[tokenId] = WorkData({
            jobId: jobId,
            reward: reward,
            deadline: deadline,
            title: title,
            deliveryUrl: deliveryUrl
        });

        return tokenId;
    }
}