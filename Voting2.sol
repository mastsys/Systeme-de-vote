// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
        address voterAddress;
    }

    struct Proposal {
        string description;
        uint voteCount;
        address proposer;
    }

    struct VoteSession {
        uint sessionId;
        uint votersNumber;
        uint voteStartingDate;
        uint voteEndingDate;
        uint abstentionVotes;
        uint blankVotes;
        uint totalVotes;
        bool isTied;
        Proposal winningProposal;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        TiedVote,
        VotesTallied,
        VoteSessionSaved
    }

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);
    event VoterRemovedFromSession(address voterAddress, uint sessionId);
    event AllProposalsForSession(uint voteSessionId, Proposal[] proposals);
    event TiedVote(uint[] tiedProposalsId);
    event AdminChoseProposal(uint proposalId);
    event VoteSessionSaved(VoteSession session);
    event AllSessions(VoteSession[] sessions);
   
    mapping(address => Voter) whitelist;
    WorkflowStatus public status;
    VoteSession[] sessions;
    VoteSession currentSession;
    Proposal[] public proposals;
    address[]  sessionVoters;
    uint[] tiedProposalsId;

    constructor() {
        status = WorkflowStatus.RegisteringVoters;
        proposals.push(Proposal("Blank Vote Proposal", 0, address(0)));
        currentSession.sessionId = 0;
        currentSession.votersNumber = 0;
        currentSession.isTied = false;
    }

    modifier checkProposalNumber() {
        require(proposals.length >= 2, "There must at least two proposals");
        _;
    }

    modifier checkProposalId(uint[] memory array, uint id) {
        bool found = false;
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == id) {
                found = true;
                break;
            }
        }
        require(found, "The id wasn't found");
        _;
    }

    function setVotersWhitelist(address _address) external onlyOwner {
        require(status == WorkflowStatus.RegisteringVoters, "There is no voters registration session in progress");
        Voter memory newVoter = Voter(true, false, 0, _address);
        whitelist[_address] = newVoter;
        currentSession.votersNumber++;
        emit VoterRegistered(_address);
    }

    function removeVoter(address _address) external onlyOwner {
        require(status == WorkflowStatus.RegisteringVoters, "There is no voters registration session in progress");
        require(whitelist[_address].isRegistered, "This address is not registered");
        whitelist[_address] = Voter(false, false, 0, _address);
        currentSession.votersNumber--;
        emit VoterRemovedFromSession(_address, currentSession.sessionId);
    }

    // Proposal Session
    function startProposalSession() external onlyOwner {
        status = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    function addProposal(string memory _proposalDescription) external {
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "There is no proposal registration session in progress");
        require(whitelist[msg.sender].isRegistered == true, "You are not registered");
        proposals.push(Proposal(_proposalDescription, 0, msg.sender));
        uint id = proposals.length - 1;
        emit ProposalRegistered(id);
    }
    
    function endProposalSession() external onlyOwner checkProposalNumber {
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "There is no proposal registration session in progress");
        status = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    // Vote Session
    function startVoteSession() external onlyOwner {
        require(status == WorkflowStatus.ProposalsRegistrationEnded, "The proposal registration session is not ended");
        status = WorkflowStatus.VotingSessionStarted;
        currentSession.voteStartingDate = block.timestamp;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function vote(uint _proposalId) external {
        require(status == WorkflowStatus.VotingSessionStarted, "There is no voting session in progress");
        require(whitelist[msg.sender].isRegistered == true, "You are not registered");
        require(whitelist[msg.sender].hasVoted == false, "You have already voted");
        proposals[_proposalId].voteCount++;
        whitelist[msg.sender].votedProposalId = _proposalId;
        whitelist[msg.sender].hasVoted = true;
        sessionVoters.push(msg.sender);
        currentSession.totalVotes++;
        emit Voted(msg.sender, _proposalId);
    }

    function endVoteSession() external onlyOwner {
        require(status == WorkflowStatus.VotingSessionStarted, "There is no voting session in progress");
        status = WorkflowStatus.VotingSessionEnded;
        currentSession.voteEndingDate = block.timestamp;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    // Tallying, managing tied vote and returning winner
    function countVotes() external onlyOwner {
        require(status == WorkflowStatus.VotingSessionEnded, "There is no ended vote to tally");
        uint voteCounter = 0;
        uint tiedProposals = 0;
        uint winningProposalId;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > voteCounter) {
                voteCounter = proposals[i].voteCount;
                winningProposalId = i;
            }
        }

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount == voteCounter) {
                tiedProposals++;
            }
        }

        if (tiedProposals > 1) {
            for (uint i = 0; i < proposals.length; i++) {
                if (proposals[i].voteCount == voteCounter) {
                    tiedProposalsId.push(i);
                }
            }
            currentSession.isTied = true;
            emit TiedVote(tiedProposalsId);
            status = WorkflowStatus.TiedVote;
            emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.TiedVote);
        } else {
            currentSession.winningProposal = proposals[winningProposalId];
            status = WorkflowStatus.VotesTallied;
            emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
        }
    }

    function adminChooseProposal(uint _proposalId) external onlyOwner checkProposalId(tiedProposalsId,_proposalId)  {
        require(status == WorkflowStatus.TiedVote, "The administrator choose the proposal only if the vote is tied");
        currentSession.winningProposal = proposals[_proposalId];
        status = WorkflowStatus.VotesTallied;
        emit AdminChoseProposal(_proposalId);
        emit WorkflowStatusChange(WorkflowStatus.TiedVote, WorkflowStatus.VotesTallied);
    } 

    function getWinner() external view returns (Proposal memory _proposal) {
        require(status == WorkflowStatus.VotesTallied, "The vote is not tallied");
        _proposal = currentSession.winningProposal;
        return _proposal;
    }

    function getVotedProposalByVoter(address _voterAddress) external view returns (uint) {
        require(status == WorkflowStatus.VotesTallied, "The vote is not tallied");
        require(whitelist[_voterAddress].isRegistered, "This address is not registered");
        return  whitelist[_voterAddress].votedProposalId; 
    }

    //Save, Get Session and Reset 
    function saveSession() external onlyOwner {
        require(status == WorkflowStatus.VotesTallied, "The vote is not tallied");
        currentSession.blankVotes = proposals[0].voteCount;
        currentSession.abstentionVotes = currentSession.votersNumber - currentSession.totalVotes;
        sessions.push(currentSession);
        emit VoteSessionSaved(currentSession);
        status = WorkflowStatus.VoteSessionSaved;
        emit WorkflowStatusChange(WorkflowStatus.VotesTallied, WorkflowStatus.VoteSessionSaved);
    }

    function getAllSessions() external returns (VoteSession[] memory) {
        emit AllSessions(sessions);
        return sessions;
    }

    function resetAndStartNewSession() external onlyOwner {
        require(status == WorkflowStatus.VoteSessionSaved, "The vote session is not saved");

        delete proposals;
        proposals.push(Proposal("Blank Vote Proposal", 0, address(0)));

        for (uint i = 0; i < sessionVoters.length; i++) {
            whitelist[sessionVoters[i]] = Voter(false, false, 0, address(0));
        }

        currentSession.sessionId++;
        currentSession.votersNumber = 0;
        currentSession.voteStartingDate = 0;
        currentSession.voteEndingDate = 0;
        currentSession.abstentionVotes = 0;
        currentSession.blankVotes = 0;
        currentSession.totalVotes = 0;
        currentSession.isTied = false;

        status = WorkflowStatus.RegisteringVoters;

        emit WorkflowStatusChange(status, WorkflowStatus.RegisteringVoters);
    }
}
