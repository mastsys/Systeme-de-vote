# Voting Smart Contract

This Solidity smart contract manages a voting system.

## Voting Session Example

To conduct a voting session, follow these steps:

1. Start the proposal session (Admin):
   - Function Call: startProposalSession()
   - Example: startProposalSession()

2. Register proposals from voters:
   - Function Call: saveProposal(string memory _proposalDescription)
   - Example: saveProposal("Proposal A")

3. End the proposal session (Admin):
   - Function Call: endProposalSession()
   - Example: endProposalSession()

4. Start the voting session (Admin):
   - Function Call: startVoteSession()
   - Example: startVoteSession()

5. Voters cast their votes:
   - Function Call: vote(uint _proposalId)
   - Example: vote(0)

6. End the voting session (Admin):
   - Function Call: endVoteSession()
   - Example: endVoteSession()

7. Count the votes and determine the winning proposal (Admin):
   - Function Call: countVotes()
   - Example: countVotes()

## Additional Functions

To retrieve voting-related information, the following functions can be used:

1. Get the winning proposal:
   - Function Call: getWinner()
   - Example: getWinner()

2. Get the proposal ID voted by a specific voter:
   - Function Call: getVotedProposalByVoter(address _voterAddress)
   - Example: getVotedProposalByVoter(0x1234567890123456789012345678901234567890)

## Version 2

1. Remove Voter
The removeVoter function allows the administrator to remove a voter.

  - Example: removeVoter(0x9876543210987654321098765432109876543210)

2. Count Votes in Case of Tie with Admin's Choice
The countVote function is used to determine the winning proposal in case of tie. 
The administrator choose the winning proposal among  the tied proposals.

  - Example: adminChooseProposal(2)

3. Save Session
The saveSession function allows the administrator to save the current voting session. 

- Example: saveSession()

4. Get All Sessions
The getAllSessions function retrieves information about all the past voting sessions.

  - Example: getAllSessions()