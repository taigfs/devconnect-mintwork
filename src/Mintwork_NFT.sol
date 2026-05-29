// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title WorkNFT
 * @dev ERC-721 credential NFT that serves as a verifiable credential of completed work.
 * Only the owner (WorkMarketplace) can mint.
 * Implements fully on-chain metadata with SVG generation for display on block explorers.
 */
contract WorkNFT is ERC721, Ownable {
    using Strings for uint256;

    uint256 public nextTokenId = 1;

    struct WorkData {
        uint256 jobId;
        uint256 reward; // WETH amount in wei (18 decimals)
        uint256 deadline; // timestamp
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

        workInfo[tokenId] =
            WorkData({jobId: jobId, reward: reward, deadline: deadline, title: title, deliveryUrl: deliveryUrl});

        return tokenId;
    }

    /**
     * @dev Returns the token URI with fully on-chain metadata.
     * Generates base64-encoded JSON with embedded SVG image.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        WorkData memory work = workInfo[tokenId];

        // Generate SVG image
        string memory svg = generateSvg(tokenId, work.title);
        string memory svgBase64 = Base64.encode(bytes(svg));

        // Format reward as decimal string
        string memory rewardFormatted = formatReward(work.reward);

        // Build JSON metadata
        string memory json = string(
            abi.encodePacked(
                '{"name":"Work Credential #',
                tokenId.toString(),
                '","description":"Completed job credential for: ',
                work.title,
                '","image":"data:image/svg+xml;base64,',
                svgBase64,
                '","attributes":[',
                '{"trait_type":"Job ID","value":"',
                work.jobId.toString(),
                '"},',
                '{"trait_type":"Reward","value":"',
                rewardFormatted,
                ' WETH"},',
                '{"trait_type":"Deadline","value":"',
                work.deadline.toString(),
                '"},',
                '{"trait_type":"Delivery URL","value":"',
                work.deliveryUrl,
                '"}',
                "]}"
            )
        );

        // Return base64-encoded JSON
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @dev Generates an SVG image for the NFT.
     */
    function generateSvg(uint256 tokenId, string memory title) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 400 400'>",
                "<defs>",
                "<linearGradient id='grad' x1='0%' y1='0%' x2='100%' y2='100%'>",
                "<stop offset='0%' style='stop-color:#667eea;stop-opacity:1'/>",
                "<stop offset='100%' style='stop-color:#764ba2;stop-opacity:1'/>",
                "</linearGradient>",
                "</defs>",
                "<rect width='400' height='400' fill='url(#grad)'/>",
                "<text x='50%' y='35%' fill='white' font-size='28' font-weight='bold' dominant-baseline='middle' text-anchor='middle'>",
                "Work Credential",
                "</text>",
                "<text x='50%' y='50%' fill='white' font-size='48' font-weight='bold' dominant-baseline='middle' text-anchor='middle'>",
                "#",
                tokenId.toString(),
                "</text>",
                "<text x='50%' y='65%' fill='white' font-size='16' dominant-baseline='middle' text-anchor='middle' opacity='0.9'>",
                truncateString(title, 30),
                "</text>",
                "<text x='50%' y='80%' fill='white' font-size='14' dominant-baseline='middle' text-anchor='middle' opacity='0.7'>",
                "Verifiable Work Credential",
                "</text>",
                "</svg>"
            )
        );
    }

    /**
     * @dev Formats reward amount from wei (18 decimals) to human-readable string.
     * Examples: 1000000000000000 wei → "0.001 WETH", 50000000000000000 → "0.05 WETH"
     */
    function formatReward(uint256 rewardWei) internal pure returns (string memory) {
        if (rewardWei == 0) return "0";

        uint256 wholePart = rewardWei / 1e18;
        uint256 fractionalPart = rewardWei % 1e18;

        if (fractionalPart == 0) {
            return wholePart.toString();
        }

        // Get up to 6 significant decimal places
        uint256 decimals = fractionalPart / 1e12; // Convert to 6 decimals

        // Remove trailing zeros
        while (decimals > 0 && decimals % 10 == 0) {
            decimals /= 10;
        }

        if (wholePart > 0) {
            return string(abi.encodePacked(wholePart.toString(), ".", uint256(decimals).toString()));
        } else {
            return string(abi.encodePacked("0.", uint256(decimals).toString()));
        }
    }

    /**
     * @dev Truncates a string to maxLength characters with ellipsis if needed.
     */
    function truncateString(string memory str, uint256 maxLength) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length <= maxLength) {
            return str;
        }

        bytes memory truncated = new bytes(maxLength);
        for (uint256 i = 0; i < maxLength - 3; i++) {
            truncated[i] = strBytes[i];
        }
        truncated[maxLength - 3] = ".";
        truncated[maxLength - 2] = ".";
        truncated[maxLength - 1] = ".";

        return string(truncated);
    }
}
