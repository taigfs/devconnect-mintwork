// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IWorkNFT {
    function mintWorkNFT(
        address to,
        uint256 jobId,
        uint256 reward,
        uint256 deadline,
        string memory title,
        string memory deliveryUrl
    ) external returns (uint256);
}

/**
 * @title WorkMarketplace
 * @dev Escrow-based job marketplace on Base.
 * USDC is held in escrow until work is approved or job is cancelled.
 * Only the marketplace can mint WorkNFT credentials upon approval.
 */
contract WorkMarketplace is ReentrancyGuard, Ownable {
    IERC20 public immutable usdc;
    IWorkNFT public immutable workNFT;

    uint256 public nextJobId;

    enum JobStatus { Created, Submitted, Paid, Cancelled }

    struct Job {
        uint256 jobId;
        address requester;
        address worker;
        uint256 reward;         // USDC amount
        uint256 deadline;       // timestamp
        string title;
        string description;
        string deliveryUrl;
        JobStatus status;
    }

    mapping(uint256 => Job) public jobs;

    /* ==================== EVENTS ==================== */

    event JobCreated(
        uint256 indexed jobId,
        address indexed requester,
        uint256 reward,
        uint256 deadline,
        string title
    );

    event JobTaken(uint256 indexed jobId, address indexed worker);

    event WorkSubmitted(
        uint256 indexed jobId,
        address indexed worker,
        string deliveryUrl
    );

    event WorkApproved(
        uint256 indexed jobId,
        address indexed requester,
        address indexed worker,
        uint256 tokenId
    );

    event JobCancelled(uint256 indexed jobId, address indexed requester);

    event WorkNFTMinted(
        uint256 indexed jobId,
        uint256 indexed tokenId,
        address indexed worker
    );

    constructor(address _usdc, address _workNFT) Ownable(msg.sender) {
        require(_usdc != address(0), "USDC address zero");
        require(_workNFT != address(0), "WorkNFT address zero");

        usdc = IERC20(_usdc);
        workNFT = IWorkNFT(_workNFT);
    }

    /**
     * @dev Create a new job and lock USDC in escrow.
     * Requester must approve this contract for the reward amount before calling.
     */
    function createJob(
        uint256 reward,
        uint256 deadline,
        string calldata title,
        string calldata description
    ) external {
        require(reward > 0, "Reward must be > 0");
        require(deadline > block.timestamp, "Deadline must be in future");
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

        // Pull USDC into escrow
        bool success = usdc.transferFrom(msg.sender, address(this), reward);
        require(success, "USDC transfer failed");

        emit JobCreated(jobId, msg.sender, reward, deadline, title);
    }

    /**
     * @dev Worker claims the job.
     * Anyone can take an open job (first-come, first-served).
     */
    function takeJob(uint256 jobId) external {
        Job storage job = jobs[jobId];

        require(job.status == JobStatus.Created, "Job not open");
        require(job.worker == address(0), "Job already taken");

        job.worker = msg.sender;

        emit JobTaken(jobId, msg.sender);
    }

    /**
     * @dev Worker submits the delivery URL after completing the work.
     */
    function submitWork(uint256 jobId, string calldata deliveryUrl) external {
        Job storage job = jobs[jobId];

        require(msg.sender == job.worker, "Not the worker");
        require(job.status == JobStatus.Created, "Invalid state for submission");
        require(bytes(deliveryUrl).length > 0, "Delivery URL required");

        job.deliveryUrl = deliveryUrl;
        job.status = JobStatus.Submitted;

        emit WorkSubmitted(jobId, msg.sender, deliveryUrl);
    }

    /**
     * @dev Requester approves the work → pays worker and mints NFT credential.
     */
    function approveWork(uint256 jobId) external nonReentrant {
        Job storage job = jobs[jobId];

        require(msg.sender == job.requester, "Not the requester");
        require(job.status == JobStatus.Submitted, "Work not submitted");
        require(job.worker != address(0), "No worker assigned");

        job.status = JobStatus.Paid;

        // 1. Pay the worker in USDC
        bool success = usdc.transfer(job.worker, job.reward);
        require(success, "USDC payment failed");

        // 2. Mint the WorkNFT credential
        uint256 tokenId = workNFT.mintWorkNFT(
            job.worker,
            job.jobId,
            job.reward,
            job.deadline,
            job.title,
            job.deliveryUrl
        );

        emit WorkApproved(jobId, job.requester, job.worker, tokenId);
        emit WorkNFTMinted(jobId, tokenId, job.worker);
    }

    /**
     * @dev Requester cancels the job and gets the escrow back.
     * Only possible if no one has taken the job yet (MVP rule).
     */
    function cancelJob(uint256 jobId) external nonReentrant {
        Job storage job = jobs[jobId];

        require(msg.sender == job.requester, "Not the requester");
        require(job.status == JobStatus.Created, "Job not cancellable");
        require(job.worker == address(0), "Job already taken");

        job.status = JobStatus.Cancelled;

        bool success = usdc.transfer(job.requester, job.reward);
        require(success, "USDC refund failed");

        emit JobCancelled(jobId, job.requester);
    }

    /* ==================== VIEW FUNCTIONS ==================== */

    function getJob(uint256 jobId) external view returns (Job memory) {
        return jobs[jobId];
    }

    function getJobBasicInfo(uint256 jobId)
        external
        view
        returns (
            address requester,
            address worker,
            uint256 reward,
            uint256 deadline,
            string memory title,
            JobStatus status
            )
    {
        Job memory job = jobs[jobId];
        return (job.requester, job.worker, job.reward, job.deadline, job.title, job.status);
    }
}