// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    uint winningProposalId;
    mapping(address => Voter) whitelist;
    Proposal[] public proposals;
    WorkflowStatus public status;

    constructor() {
        status = WorkflowStatus.RegisteringVoters;
    }

    function setVotersWhitelist(address _address) external onlyOwner {
        require(status == WorkflowStatus.RegisteringVoters, "There is no voter registration session in progress");
        whitelist[_address] = Voter(true, false, 0);
        emit VoterRegistered(_address);
    }

    // Proposal Session
    function startProposalSession() external onlyOwner {
        status = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    function saveProposal(string memory _proposalDescription) external {
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "There is no proposal registration session in progress");
        require(whitelist[msg.sender].isRegistered == true, "You are not registered");
        proposals.push(Proposal(_proposalDescription, 0));
        uint id = proposals.length - 1;
        emit ProposalRegistered(id);
    }

    function endProposalSession() external onlyOwner {
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "There is no proposal registration session in progress");
        status = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    // Vote Session
    function startVoteSession() external onlyOwner {
        require(status == WorkflowStatus.ProposalsRegistrationEnded, "The proposal registration session is not ended");
        status = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function vote(uint _proposalId) external {
        require(status == WorkflowStatus.VotingSessionStarted, "There is no voting session in progress");
        require(whitelist[msg.sender].isRegistered == true, "You are not registered");
        require(whitelist[msg.sender].hasVoted == false, "You have already voted");
        proposals[_proposalId].voteCount++;
        whitelist[msg.sender].votedProposalId = _proposalId;
        whitelist[msg.sender].hasVoted = true;
        emit Voted(msg.sender, _proposalId);
    }

    function endVoteSession() external onlyOwner {
        require(status == WorkflowStatus.VotingSessionStarted, "There is no voting session in progress");
        status = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    // Tallying and returning winner
    function countVotes() external onlyOwner {
        require(status == WorkflowStatus.VotingSessionEnded, "There is no ended vote");
        uint voteCounter = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > voteCounter) {
                voteCounter = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
        status = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

    function getWinner() public view returns (Proposal memory proposal) {
        require(status == WorkflowStatus.VotesTallied, "The vote is not tallied");
        proposal = proposals[winningProposalId];
        return proposal;
    }

    function getVotedProposalByVoter(address _voterAddress) external view returns (uint) {
        require(whitelist[_voterAddress].isRegistered, "This address is not registered");
        return  whitelist[_voterAddress].votedProposalId; 
    }
}
