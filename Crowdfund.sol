//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

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

    // Maps each id to a campaign
    mapping(uint256 => Campaign) public campaigns;
    // Maps each id to an address that has pledged to a campaign
    mapping(uint256 => mapping(address => uint256)) public pledges;

    struct Campaign {
        uint256 id;
        address owner;
        uint256 target;
        uint256 current;
        uint256 startAt;
        uint256 endAt;
    }

    function createPledge(uint256 _campaign_id) public payable {
        Campaign storage campaign = campaigns[_campaign_id];

        if (campaign.target == 0) {
            revert CampaignNotFound(msg.sender, _campaign_id);
        }
        if (msg.value == 0) {
            revert InvalidAmount(msg.sender);
        }
        if (block.timestamp > campaign.endAt) {
            revert CampaignIsInactive(msg.sender, _campaign_id);
        }

        pledges[_campaign_id][msg.sender] += msg.value;
        campaign.current += msg.value;

        emit PledgeCreated(msg.sender, campaign.id, msg.value);
    }

    function startCampaign(uint256 _target, uint256 _durationDays) public {
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
            endAt: _endAt
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
