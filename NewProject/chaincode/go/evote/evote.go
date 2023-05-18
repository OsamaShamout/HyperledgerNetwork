package main

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type ElectionContract struct {
	contractapi.Contract
}

type User struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	School   string `json:"school"`
	Standing string `json:"standing"`
}

type Election struct {
	ID         string      `json:"id"`
	Candidates []Candidate `json:"candidates"`
	StartTime  string      `json:"start_time"`
	EndTime    string      `json:"end_time"`
}

type Candidate struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	School   string `json:"school"`
	Standing string `json:"standing"`
}

type Vote struct {
	ElectionID    string `json:"election_id"`
	CandidateID   string `json:"candidate_id"`
	VoterSchool   string `json:"voter_school"`
	VoterStanding string `json:"voter_standing"`
	VoterID       string `json:"voter_id"`
}

type ElectionResult struct {
	ElectionID string           `json:"election_id"`
	Results    map[string]int32 `json:"results"` // Key: CandidateID, Value: Vote count
}

func (s *ElectionContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	fmt.Printf("Welcome to the eVoting system of the future!\n")

	return nil
}

// CreateElection creates a new election on the ledger
// Args are electionID, candidatesJSON, startTime, endTime
func (s *ElectionContract) CreateElection(ctx contractapi.TransactionContextInterface, electionID string, candidates_received string, startTime string, endTime string) error {
	// Check if the election already exists
	electionCheck, err := ctx.GetStub().GetState(electionID)
	if err != nil || electionCheck != nil {
		return fmt.Errorf("The Election has already been initalized.")
	}
	var candidates []Candidate
	err1 := json.NewDecoder(strings.NewReader(candidates_received)).Decode(&candidates)
	if err1 != nil {
		fmt.Printf("Error parsing candidate data. %s\n", err1.Error())
		fmt.Printf("candidatesReceived as bytes: %v\n", []byte(candidates_received))
		return fmt.Errorf("Error parsing candidate data. %s", err1.Error())
	}

	// err := json.Unmarshal([]byte(candidates_received), &candidates)
	// if err != nil {
	//     fmt.Printf("Error parsing candidate data. %s\n", err.Error())
	//     fmt.Printf("candidates_received as bytes: %v\n", []byte(candidates_received))
	//     return fmt.Errorf("Error parsing candidate data. %s", err.Error())
	// }

	election := Election{
		ID:         electionID,
		Candidates: candidates,
		StartTime:  startTime,
		EndTime:    endTime,
	}

	electionJSON, err := json.Marshal(election)
	if err != nil {
		return fmt.Errorf("Error marshaling election data. %s", err.Error())
	}

	err = ctx.GetStub().PutState(electionID, electionJSON)
	if err != nil {
		return fmt.Errorf("Error saving election data to the ledger. %s", err.Error())
	}

	return nil
}

func (s *ElectionContract) Vote(ctx contractapi.TransactionContextInterface, electionID string, candidateID string, voterID string) error {
	// Check if the election exists
	electionBytes, err := ctx.GetStub().GetState(electionID)
	if err != nil {
		return fmt.Errorf("Error retrieving election data from the ledger. %s", err.Error())
	}
	if electionBytes == nil {
		return fmt.Errorf("Election not found.")
	}

	var election Election
	err = json.Unmarshal(electionBytes, &election)
	if err != nil {
		return fmt.Errorf("Error unmarshaling election data. %s", err.Error())
	}
	// Check if the election is open
	currentTime := time.Now().Unix()
	parseStartUnixTime, err := strconv.ParseInt(election.StartTime, 10, 64)
	if err != nil {
		fmt.Println("Error converting string to int64:", err)
		return fmt.Errorf("Error converting string to int64:", err)
	}

	parseEndUnixTime, err := strconv.ParseInt(election.EndTime, 10, 64)
	if err != nil {
		fmt.Println("Error converting string to int64:", err)
		return fmt.Errorf("Error converting string to int64:", err)
	}
	if currentTime < parseStartUnixTime {
		return fmt.Errorf("Voting has not started yet for this election.")
	}
	// Check if the election has ended
	if currentTime > parseEndUnixTime {
		return fmt.Errorf("Voting has ended for this election.")
	}

	// Check if the specified candidate exists in the election
	var candidateCandidate Candidate
	for _, candidate := range election.Candidates {
		if candidate.ID == candidateID {
			candidateCandidate = candidate
			break
		}
	}
	// Check if the candidate exists
	if candidateCandidate.ID == "" {
		return fmt.Errorf("Candidate not found in the specified election.")
	}

	// Check if the voter exists
	voterBytes, err := ctx.GetStub().GetState("USER_" + voterID)
	if err != nil {
		return fmt.Errorf("Error retrieving voter data from the ledger. %s", err.Error())
	}
	if voterBytes == nil {
		return fmt.Errorf("Voter not found.")
	}
	var voter User
	err = json.Unmarshal(voterBytes, &voter)
	if err != nil {
		return fmt.Errorf("Error unmarshaling voter data. %s", err.Error())
	}
	//Check if school is empty
	if candidateCandidate.School == "" {
		return fmt.Errorf("Candidate not found in the specified election.")
	}
	// Check if the voter's school matches the candidate's school
	if voter.School != candidateCandidate.School {
		return fmt.Errorf("The voter's school does not match the candidate's school.")
	}

	var voterSchool = voter.School
	// Check if the voter's standing matches the candidate's standing
	if (voter.Standing == "Freshman" || voter.Standing == "Sophomore") && candidateCandidate.Standing != "Sophomore" && candidateCandidate.Standing != "Freshman" {
		return fmt.Errorf("Freshman or Sophomore cannot vote for Junior or Senior candidates.")
	}
	if (voter.Standing == "Junior" || voter.Standing == "Senior") && candidateCandidate.Standing != "Junior" && candidateCandidate.Standing != "Senior" {
		return fmt.Errorf("Junior or Senior cannot vote for Freshman or Sophomore candidates.")
	}
	var voterStanding = voter.Standing
	// Check if the voter has already voted in this election
	voteKey := fmt.Sprintf("VOTE_%s_%s", electionID, voterID)
	voteCheck, err := ctx.GetStub().GetState(voteKey)
	if err != nil || voteCheck != nil {
		return fmt.Errorf("The voter has already voted in this election.")
	}

	// Record the vote
	vote := Vote{
		ElectionID:    electionID,
		CandidateID:   candidateID,
		VoterSchool:   voterSchool,
		VoterStanding: voterStanding,
		VoterID:       voterID,
	}

	voteJSON, err := json.Marshal(vote)
	if err != nil {
		return fmt.Errorf("Error marshaling vote data. %s", err.Error())
	}

	err = ctx.GetStub().PutState(voteKey, voteJSON)
	if err != nil {
		return fmt.Errorf("Error saving vote data to the ledger. %s", err.Error())
	}

	return nil
}

func (s *ElectionContract) GetElectionResults(ctx contractapi.TransactionContextInterface, electionID string) (*ElectionResult, error) {
	results := make(map[string]int32)
	queryString := fmt.Sprintf("{\"selector\":{\"_id\":{\"$regex\":\"^VOTE_%s_\"}}}", electionID)

	queryResults, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("Error querying the ledger for votes. %s", err.Error())
	}
	defer queryResults.Close()

	for queryResults.HasNext() {
		queryResponse, err := queryResults.Next()
		if err != nil {
			return nil, fmt.Errorf("Error processing query results. %s", err.Error())
		}

		var vote Vote
		err = json.Unmarshal(queryResponse.Value, &vote)
		if err != nil {
			return nil, fmt.Errorf("Error unmarshaling vote data. %s", err.Error())
		}

		results[vote.CandidateID]++
	}

	electionResult := &ElectionResult{
		ElectionID: electionID,
		Results:    results,
	}

	return electionResult, nil
}

func (s *ElectionContract) GetElectionDetails(ctx contractapi.TransactionContextInterface, electionID string) (*Election, error) {
	electionBytes, err := ctx.GetStub().GetState(electionID)
	if err != nil {
		return nil, fmt.Errorf("Error retrieving election data from the ledger. %s", err.Error())
	}
	if electionBytes == nil {
		return nil, fmt.Errorf("Election not found.")
	}

	var election Election
	err = json.Unmarshal(electionBytes, &election)
	if err != nil {
		return nil, fmt.Errorf("Error unmarshaling election data. %s", err.Error())
	}

	return &election, nil
}

func (s *ElectionContract) GetCandidateDetails(ctx contractapi.TransactionContextInterface, electionID string, candidateID string) (*Candidate, error) {
	electionBytes, err := ctx.GetStub().GetState(electionID)
	if err != nil {
		return nil, fmt.Errorf("Error retrieving election data from the ledger. %s", err.Error())
	}
	if electionBytes == nil {
		return nil, fmt.Errorf("Election not found.")
	}

	var election Election
	err = json.Unmarshal(electionBytes, &election)
	if err != nil {
		return nil, fmt.Errorf("Error unmarshaling election data. %s", err.Error())
	}

	for _, candidate := range election.Candidates {
		if candidate.ID == candidateID {
			return &candidate, nil
		}
	}

	return nil, fmt.Errorf("Candidate not found in the specified election.")
}

func (c *ElectionContract) RegisterUser(ctx contractapi.TransactionContextInterface, userID string, name string, userSchool string, userStanding string) error {

	// Check if the user is already registered
	userBytes, err := ctx.GetStub().GetState("USER_" + userID)
	if err != nil {
		return fmt.Errorf("Error retrieving user data from the ledger. %s", err.Error())
	}
	if userBytes != nil {
		return fmt.Errorf("User already registered.")
	}
	if userStanding != "Junior" && userStanding != "Senior" && userStanding != "Freshman" && userStanding != "Sophomore" {
		return fmt.Errorf("Student has invalid standing.")
	}
	if userSchool != "School of Arts and Sciences" && userSchool != "School of Business" && userSchool != "School of Architecture and Design" {
		return fmt.Errorf("Student has invalid school.")
	}
	//Create new user
	user := User{
		ID:       userID,
		Name:     name,
		School:   userSchool,
		Standing: userStanding,
	}

	userJSON, err := json.Marshal(user)
	if err != nil {
		return fmt.Errorf("Error marshaling user data. %s", err.Error())
	}

	err = ctx.GetStub().PutState("USER_"+userID, userJSON)
	if err != nil {
		return fmt.Errorf("Error saving user data to the ledger. %s", err.Error())
	}

	return nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&ElectionContract{})

	if err != nil {
		fmt.Printf("Error creating e-voting chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting e-voting chaincode: %s", err.Error())
	}
}

