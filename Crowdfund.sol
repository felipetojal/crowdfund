//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

error InvalidTargetAmount(address sender);
error InvalidDuration(address sender);

contract Crowdfund {
    uint256 campaignId;
    uint256 pledgeId;
    address owner;

    constructor() {
        campaignId = 0;
        pledgeId = 0;
        owner = msg.sender;
    }

    event CampaignStarted(
        address owner,
        uint256 indexed id,
        uint256 indexed amount,
        uint256 startAt,
        uint256 indexed endAt
    );

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => Pledge) public pledges;

    struct Pledge {
        uint256 pledgeId;
        uint256 campaignId;
        uint256 amount;
        address owner;
    }

    struct Campaign {
        uint256 id;
        address owner;
        uint256 target;
        uint256 current;
        uint256 startAt;
        uint256 endAt;
        bool active;
    }

    function startCampaign(uint256 _target, uint256 _duration) public {
        campaignId += 1;

        // Checking the parameters
        if (_target == 0) {
            revert InvalidTargetAmount(msg.sender);
        }
        if (_duration == 0) {
            revert InvalidDuration(msg.sender);
        }

        uint256 _startAt = block.timestamp;
        uint256 _endAt = _startAt + _duration;

        campaigns[campaignId] = Campaign({
            id: campaignId,
            owner: msg.sender,
            target: _target,
            current: 0,
            startAt: _startAt,
            endAt: _endAt,
            active: true
        });

        emit CampaignStarted(owner, campaignId, _target, _startAt, _endAt);
    }
}
