//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title FundingDAO
 * @dev The FundingDAO contract can create a Proposal by stakeholders, where only StakeHolders can vote, tho 
 * members can become stakeholders by providing funds to the contract. The voting period is of two days and there
 * is count of in favour votes and Againts votes
 */
contract FundingDAO {
    uint32 public votingPeriod = 2 days;

    uint256 public proposalsCount = 0;

    struct Proposal {
        uint256 id;
        uint256 amount;
        uint256 livePeriod;
        uint256 voteInFavor;
        uint256 voteAgainst;
        string title;
        string desc;
        bool isCompleted;
        bool paid;
        bool isPaid;
        address receiverAddress; //payable
        address proposer;
        uint256 totalFundRaised;
        Funding[] funders;
    }

    struct Funding {
        address payer;
        uint256 amount;
        uint256 timestamp;
    }

    mapping(uint256 => Proposal) private proposals;
    mapping(address => uint256) private stakeholders;
    mapping(address => uint256) private members;
    mapping(address => bool) private isMember;
    mapping(address => bool) private isStakeholder;
    mapping(address => uint256[]) private votes;

    /**
     * @dev The FundingDAO constructor sets the original `owner` of the contract to be StakeHolder.
     */

    constructor() {
        isStakeholder[msg.sender] = true;
        isMember[msg.sender] = true;
        members[msg.sender] = 500;
        stakeholders[msg.sender] = 500;
    }
    /**
     * @dev Emitted when the  New Member is added
     */
    event NewMember(address indexed fromAddress, uint256 amount);

    /**
     * @dev Emitted when the  New Proposal is added.
     */
    event NewProposal(address indexed proposer, uint256 amount);

    /**
     * @dev Emitted when the  New Paymnet is added
     */
    event Payment(
        address indexed stakeholder,
        address indexed projectAddress,
        uint256 amount
    );
    /**
     * @dev Throws if called by any account other than the Member.
     */
    modifier onlyMember() {
        require(isMember[msg.sender]);
        _;
    }
    /**
     * @dev Throws if called by any account other than the Stake Holder.
     */
    modifier onlyStakeholder() {
        require(isStakeholder[msg.sender]);
        _;
    }

    /**
     * @dev Create a new proposal.
     *
     * * Requirements:
     *
     * - `Title` cannot be the Empty String.
     * - `desc` cannot be the Empty String.
     - `receiverAddress` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     *
     *Emits a {NewProposal} event.
     */
    function createProposal(
        string calldata title,
        string calldata desc,
        address receiverAddress,
        uint256 amount
    ) public onlyMember {
        // require( msg.value == 0 // 0 for now since we don't have any token );
        uint256 proposalId = proposalsCount;
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.desc = desc;
        proposal.title = title;
        proposal.receiverAddress = receiverAddress; // payable(receiverAddress);
        proposal.proposer = msg.sender; // payable(receiverAddress);
        proposal.amount = amount;
        proposal.livePeriod = block.timestamp + votingPeriod;
        proposal.isPaid = false;
        proposal.isCompleted = false;
        proposalsCount++;
        emit NewProposal(msg.sender, amount);
    }
     /**
     * @dev Returns the list of all proposal made by caller.
     */
     
    function getAllProposals() public view returns (Proposal[] memory) {
        Proposal[] memory tempProposals = new Proposal[](proposalsCount);
        for (uint256 index = 0; index < proposalsCount; index++) {
            tempProposals[index] = proposals[index];
        }
        return tempProposals;
    }
     /**
     * @dev Returns the proposal by proposal ID.
     */
    function getProposal(uint256 proposalId)
        public
        view
        returns (Proposal memory)
    {
        return proposals[proposalId];
    }
    /**
     * @dev Returns the Vote array of caller.
     * Requirements:
     *
     * - `Caller` must be a stakeholder.
     */
    function getVotes() public view onlyStakeholder returns (uint256[] memory) {
        return votes[msg.sender];
    }

    /**
     * @dev Returns the balance of stakeholder.
     * Requirements:
     *
     * - `Caller` must be a stakeholder.
     */
    function getStakeholderBal() public view onlyStakeholder returns (uint256) {
        return stakeholders[msg.sender];
    }


   /**
     * @dev Returns the balance of Member.
     * Requirements:
     *
     * - `Caller` must be a Member.
     */
    function getMemberBal() public view onlyMember returns (uint256) {
        return members[msg.sender];
    }

    /*
     * @dev Sets ...........fill
     * Requirements:
     *
     * - `Caller` must be a stakeholder.
     */
    function vote(uint256 proposalId, bool inFavour) public onlyStakeholder {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.isCompleted || proposal.livePeriod <= block.timestamp) {
            proposal.isCompleted = true;
            revert("Time period of this proposal is ended.");
        }
        for (uint256 i = 0; i < votes[msg.sender].length; i++) {
            if (proposal.id == votes[msg.sender][i])
                revert("You can only vote once.");
        }

        if (inFavour) proposal.voteInFavor++;
        else proposal.voteAgainst++;

        votes[msg.sender].push(proposalId);
    }

    /*
     * @dev provide funds to the contract
     * Requirements:
     *
     * - `Caller` must be a stakeholder.
     */
    function provideFunds(uint256 proposalId, uint256 fundAmount)
        public
        payable
        onlyStakeholder
    {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.isPaid) revert("Required funds are provided.");
        if (proposal.voteInFavor <= proposal.voteAgainst)
            revert("This proposal is not selected for funding.");
        if (proposal.totalFundRaised >= proposal.amount)
            revert("Required funds are provided.");
        proposal.totalFundRaised += fundAmount;
        proposal.funders.push(Funding(msg.sender, fundAmount, block.timestamp));
        if (proposal.totalFundRaised >= proposal.amount) {
            proposal.isCompleted = true;
        }
    }

    /*
     * @dev release funding from contract
     * Requirements:
     *
     * - `Caller` must be a stakeholder.
     */

    function releaseFunding(uint256 proposalId) public payable onlyStakeholder {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.totalFundRaised <= proposal.amount) {
            revert("Required funds are not met. Please provider funds.");
        }
        // proposal.receiverAddress.transfer(proposal.totalFundRaised);
        proposal.isPaid = true;
        proposal.isCompleted = true;
    }

     /*
     * @dev release funds from contract
     * Requirements:
     *
     * - `Caller` must be a stakeholder.
     */
    function createStakeholder() public payable {
        uint256 amount = msg.value;
        if (!isStakeholder[msg.sender]) {
            uint256 total = members[msg.sender] + amount;
            if (total >= 2 ether) {
                isStakeholder[msg.sender] = true;
                isMember[msg.sender] = true;
                stakeholders[msg.sender] = total;
                members[msg.sender] += amount;
            } else {
                isMember[msg.sender] = true;
                members[msg.sender] += amount;
            }
        } else {
            members[msg.sender] += amount;
            stakeholders[msg.sender] += amount;
        }
    }
}
