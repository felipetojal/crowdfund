//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

/**
 * @title Decentralized Crowdfunding Platform
 * @author felipeTojal
 * @notice Allows users to create funding campaigns and back them with ETH.
 * @dev Implements strict Checks-Effects-Interactions (CEI) and pull-payments
 *      for all refunds and claims to prevent reentrancy and DoS attacks.
 */
contract Crowdfund {
    uint256 campaign_id;
    address owner;

    constructor() {
        campaign_id = 0;
        owner = msg.sender;
    }

    error InvalidAmount(address sender);
    error InvalidDuration(address sender);
    error CampaignNotFound(address sender, uint256 id);
    error CampaignIsInactive(address sender, uint256 id);
    error NoFundsAvailable(address sender, uint256 id);
    error UnableToCompleteTransaction(
        address sender,
        uint256 id,
        uint256 amount
    );
    error OnlyCampaignOwnerAllowed(address sender, uint256 id);
    error TargetNotAchieved(uint256 id, uint256 current);
    error CampaignHasNotEnded(uint256 id, uint256 endAt);
    error CampaignHasNotFailed(uint256 id, uint256 amount);
    error FundsAlreadyClaimed(address sender, uint256 id);

    event CampaignStarted(
        address owner,
        uint256 indexed id,
        uint256 indexed amount,
        uint256 startAt,
        uint256 indexed endAt
    );
    event PledgeCreated(
        address indexed owner,
        uint256 indexed campaignId,
        uint256 amount
    );
    event FundsRefunded(address owner, uint256 id, uint256 amount);
    event FundsClaimed(address owner, uint256 id, uint256 amount);

    mapping(uint256 => Campaign) public campaigns;
    /// @dev Maps Campaign ID => Backer Address => Amount Pledged in Wei
    mapping(uint256 => mapping(address => uint256)) public pledges;

    struct Campaign {
        uint256 id;
        address owner; // The creator of the campaign
        uint256 target; // Funding goal in wei
        uint256 current; // Amount raised so far in wei
        uint256 startAt; // Unix timestamp of creation
        uint256 endAt; // Unix timestamp of deadline
        bool claimed; // True if the creator has withdrawn the funds
    }

    modifier activeCampaign(uint256 id) {
        if (block.timestamp > campaigns[id].endAt) {
            revert CampaignIsInactive(msg.sender, id);
        }
        _;
    }

    modifier onlyCampaignOwner(uint256 id) {
        if (campaigns[id].owner != msg.sender) {
            revert OnlyCampaignOwnerAllowed(msg.sender, id);
        }
        _;
    }

    modifier checkClaimed(uint256 id) {
        if (campaigns[id].claimed) {
            revert FundsAlreadyClaimed(msg.sender, id);
        }
        _;
    }

    function claim(uint256 id) external onlyCampaignOwner(id) checkClaimed(id) {
        Campaign storage campaign = campaigns[id];

        if (campaign.target > campaign.current) {
            revert TargetNotAchieved(id, campaign.current);
        }
        if (campaign.endAt > block.timestamp) {
            revert CampaignHasNotEnded(id, campaign.endAt);
        }

        campaign.claimed = true;

        (bool success, ) = payable(msg.sender).call{value: campaign.current}(
            ""
        );
        if (!success) {
            revert UnableToCompleteTransaction(
                msg.sender,
                id,
                campaign.current
            );
        }

        emit FundsClaimed(msg.sender, id, campaign.current);
    }

    function withdraw(uint256 id, uint256 amount) external activeCampaign(id) {
        uint256 funds = pledges[id][msg.sender];
        if (amount > funds) {
            revert NoFundsAvailable(msg.sender, id);
        }

        funds -= amount;

        campaigns[id].current -= amount;

        pledges[id][msg.sender] = funds;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert UnableToCompleteTransaction(msg.sender, id, amount);
        }

        emit FundsRefunded(msg.sender, id, amount);
    }

    /**
     * @notice Allows a backer to retrieve their ETH if a campaign fails.
     * @dev Bypasses the activeCampaign modifier to utilize lazy evaluation.
     *      Reverts if the campaign is still active or if the funding target was met.
     * @param _campaign_id The ID of the failed campaign.
     */
    function refund(uint256 _campaign_id) external {
        Campaign storage campaign = campaigns[_campaign_id];
        if (campaign.endAt > block.timestamp) {
            revert CampaignHasNotEnded(_campaign_id, campaign.endAt);
        }

        if (campaign.current >= campaign.target) {
            revert CampaignHasNotFailed(_campaign_id, campaign.endAt);
        }

        uint256 credit = pledges[_campaign_id][msg.sender];
        pledges[_campaign_id][msg.sender] = 0;
        if (credit == 0) {
            revert NoFundsAvailable(msg.sender, _campaign_id);
        }

        campaigns[_campaign_id].current -= credit;

        (bool success, ) = payable(msg.sender).call{value: credit}("");
        if (!success) {
            revert UnableToCompleteTransaction(
                msg.sender,
                _campaign_id,
                credit
            );
        }

        emit FundsRefunded(msg.sender, _campaign_id, credit);
    }

    /**
     * @notice Allows a user to back an active campaign.
     * @dev msg.value is used as the pledge amount. Updates both the campaign total and the user's ledger.
     * @param _campaign_id The ID of the campaign to fund.
     */
    function createPledge(
        uint256 _campaign_id
    ) external payable activeCampaign(_campaign_id) {
        Campaign storage campaign = campaigns[_campaign_id];

        if (campaign.target == 0) {
            revert CampaignNotFound(msg.sender, _campaign_id);
        }
        if (msg.value == 0) {
            revert InvalidAmount(msg.sender);
        }

        pledges[_campaign_id][msg.sender] += msg.value;
        campaign.current += msg.value;

        emit PledgeCreated(msg.sender, campaign.id, msg.value);
    }

    function startCampaign(uint256 _target, uint256 _durationDays) external {
        campaign_id += 1;

        if (_target == 0) {
            revert InvalidAmount(msg.sender);
        }
        if (_durationDays < 1) {
            revert InvalidDuration(msg.sender);
        }

        uint256 _startAt = block.timestamp;
        uint256 _endAt = _startAt + (_durationDays * 1 days);

        campaigns[campaign_id] = Campaign({
            id: campaign_id,
            owner: msg.sender,
            target: _target,
            current: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit CampaignStarted(
            msg.sender,
            campaign_id,
            _target,
            _startAt,
            _endAt
        );
    }
}
