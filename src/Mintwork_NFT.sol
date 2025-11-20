// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface IWorkNFT {
    function mintWorkNft(
        address to,
        uint256 jobId,
        uint256 reward,
        uint256 deadline,
        string memory title,
        string memory deliveryUrl
    ) external returns (uint256);
}

contract WorkMarketplace is ReentrancyGuard, Ownable {
    // Token used for escrowed payments (e.g., WETH)
    IERC20 public immutable WETH;

    // Reference to the WorkNFT contract, responsible for minting credentials
    IWorkNFT public immutable WORK_NFT;

    // Auto-incrementing job counter
    uint256 public nextJobId;

    // Possible states a job can be in
    enum JobStatus { Created, Submitted, Paid, Cancelled }

    // Base job structure stored on-chain
    struct Job {
        uint256 jobId;
        address requester;
        address worker;
        uint256 reward;         // Escrowed amount
        uint256 deadline;       // Unix timestamp
        string title;
        string description;
        string deliveryUrl;
        JobStatus status;
    }

    // Maps jobId → Job data
    mapping(uint256 => Job> public jobs;

    constructor(address _weth, address _workNft) Ownable(msg.sender) {
        require(_weth != address(0), "WETH address zero");
        require(_workNft != address(0), "WorkNFT address zero");

        WETH = IERC20(_weth);
        WORK_NFT = IWorkNFT(_workNft);
    }

    // Creates a new job and locks the reward in escrow
    function createJob(
        uint256 reward,
        uint256 deadline,
        string calldata title,
        string calldata description
    ) external {
        require(reward > 0, "Reward must be > 0");
        require(deadline > block.timestamp, "Deadline must be in the future");
        require(bytes(title).length > 0, "Title required");

        uint256 jobId = nextJobId++;

        jobs[jobId] = Job({
            jobId: jobId,
            requester: msg.sender,
            worker: address(0),
            reward: reward,
            deadline: deadline,
            title: title,
            description: description,
            deliveryUrl: "",
            status: JobStatus.Created
        });

        // Pulls tokens from requester → escrow
        WETH.transferFrom(msg.sender, address(this), reward);
    }

    // A worker accepts the job if it is still open
    function takeJob(uint256 jobId) external {
        Job storage job = jobs[jobId];

        require(job.status == JobStatus.Created, "Job not open");
        require(job.worker == address(0), "Job already taken");

        job.worker = msg.sender;
    }

    // Worker submits the delivery URL when the work is completed
    function submitWork(uint256 jobId, string calldata deliveryUrl) external {
        Job storage job = jobs[jobId];

        require(msg.sender == job.worker, "Not the worker");
        require(job.status == JobStatus.Created, "Invalid state for submission");
        require(bytes(deliveryUrl).length > 0, "Delivery URL required");

        job.deliveryUrl = deliveryUrl;
        job.status = JobStatus.Submitted;
    }

    // Requester approves completed work → releases payment + mints NFT credential
    function approveWork(uint256 jobId) external nonReentrant {
        Job storage job = jobs[jobId];

        require(msg.sender == job.requester, "Not the requester");
        require(job.status == JobStatus.Submitted, "Work not submitted");
        require(job.worker != address(0), "No worker assigned");

        // Update status before transferring funds
        job.status = JobStatus.Paid;

        // Transfer escrow to worker
        WETH.transfer(job.worker, job.reward);

        // Mint NFT credential representing completed work
        WORK_NFT.mintWorkNft(
            job.worker,
            job.jobId,
            job.reward,
            job.deadline,
            job.title,
            job.deliveryUrl
        );
    }

    // Requester cancels an unclaimed job and retrieves the escrow
    function cancelJob(uint256 jobId) external nonReentrant {
        Job storage job = jobs[jobId];

        require(msg.sender == job.requester, "Not the requester");
        require(job.status == JobStatus.Created, "Job not cancellable");
        require(job.worker == address(0), "Job already taken");

        job.status = JobStatus.Cancelled;

        // Refund full escrow
        WETH.transfer(job.requester, job.reward);
    }
}
