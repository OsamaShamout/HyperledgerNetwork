const { Gateway, Wallets, TxEventHandler, GatewayOptions, DefaultEventHandlerStrategies, TxEventHandlerFactory } = require('fabric-network');
const fs = require('fs');
const path = require("path")
const log4js = require('log4js');
const logger = log4js.getLogger('BasicNetwork');
const util = require('util')
const { log } = require('console');
const helper = require('./helper')

const invokeTransaction = async(channelName, chaincodeName, fcn, args, username, org_name) => {
    try {
        logger.debug(util.format('\n============ invoke transaction on channel %s ============\n', channelName));
        logger.debug(util.format('\nthe org_name is: %s ', "Org1"));
        // load the network configuration
        // const ccpPath =path.resolve(__dirname, '..', 'config', 'connection-org1.json');
        // const ccpJSON = fs.readFileSync(ccpPath, 'utf8')
        const ccp = await helper.getCCP("Org1") //JSON.parse(ccpJSON);

        args = JSON.parse(args);
        console.log('channeName is : ', channelName);
        console.log('chaincode name is : ', chaincodeName);
        console.log('function requested is : ', fcn);
        console.log('args provided : ', args);
        console.log('arg1: ', args[0]);
        console.log('arg2: ', args[1]);
        console.log('arg3: ', args[2]);
        console.log('arg4: ', args[3]);

        // Create a new file system based wallet for managing identities.
        const walletPath = await helper.getWalletPath("Org1") //path.join(process.cwd(), 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the user.
        let identity = await wallet.get(username);
        if (!identity) {
            console.log("An identity for the user " + "does not exist in the wallet, so please make sure you are registered for this election ");
            console.log('Run the registerUser.js application before retrying');
            return "An identity for the user ${username} does not exist in the wallet, so please make sure you are registered for this election.";
        }

        //Define the event strategy for the gateway. The transaction commit event is
        const connectOptions = {
            wallet,
            identity: username,
            discovery: { enabled: true, asLocalhost: true },
            eventHandlerOptions: {
                commitTimeout: 100,
                strategy: DefaultEventHandlerStrategies.NETWORK_SCOPE_ALLFORTX //all peers must endorse the transaction
            }
            // transaction: {
            //     strategy: createTransactionEventhandler()
            // }
        }

        // Create a new gateway for connecting to our peer node.
        const gateway = new Gateway();
        await gateway.connect(ccp, connectOptions);

        // Get the network (channel) our contract is deployed to.
        const network = await gateway.getNetwork(channelName);

        const contract = network.getContract(chaincodeName);
        let result
        let message;

        if (fcn === "Vote") {
            console.log('Function: ', fcn);
            // Args: electionID string, candidateID string, voterID string
            if (args.length !== 3) {
                console.log('Invocation requires Vote function to have 3 arguments but got', args.length);
                return 'Invocation requires Vote function to have 3 arguments but got ' + args.length; //gets back to result
            }

            const electionID = args[0];
            const candidateID = args[1];
            const voterID = args[2];
            console.log('Function: ', fcn);
            console.log('Election: ', electionID, ' Candidate: ', candidateID, ' Voter: ', voterID);

            result = await contract.submitTransaction(fcn, electionID, candidateID, voterID);

            message = "Successfully voted for candidate" +
                candidateID + " in election " + electionID + " by voter " + voterID + ".";

            await gateway.disconnect();

            let response = {
                message: message
            };

            return response;
        } else if (fcn === "CreateElection" && args.length === 4) {
            if (username === "admin") {
                // CreateElection creates a new election on the ledger
                //Args are electionID, candidatesJSON, startTime, endTime
                var [electionID, candidates, startTime, endTime] = args;
                // Perform input validation checks
                if (!electionID || typeof electionID !== 'string') {
                    throw new Error('Invalid election ID');
                }

                if (!/^Election\d+$/.test(electionID)) {
                    throw new Error('Please provide an election with the format Election followed by a number');
                }
                console.log("Successfully passed the election ID test.");
                console.log("Candidates receives are: ", candidates);
                console.log("Successfully passed the Candidates List test.");
                console.log("Successfully converted candidates to JSON string. " + candidates.toString());
                console.log("Start time is: ", startTime);
                // if (!startTime || typeof startTime !== 'string' || startTime < 0) { // we want it as a string to not be interepreted diff (leading 0 for ex.)
                //     throw new Error('Invalid start time');
                // }

                if (!/^\d{10}$/.test(startTime)) {
                    throw new Error('Invalid UNIX timestamp. Please provide a valid numeric end time value greater than the current time in UNIX seconds time (10 digits).');
                }
                console.log("Start time is: ", startTime);
                const currentTimestampMilliseconds = Date.now(); // Get the current timestamp in milliseconds
                const currentTimestampSeconds = Math.floor(currentTimestampMilliseconds / 1000); // Convert milliseconds to seconds

                const bufferSeconds = 300; // Buffer time in seconds (5 minutes)
                const adminTimestampSeconds = startTime + bufferSeconds; // Add the buffer time for the admin

                console.log("Current timestamp in milliseconds is: ", currentTimestampMilliseconds);
                console.log("Current timestamp in seconds is: ", currentTimestampSeconds);
                console.log("Admin timestamp in seconds is: ", adminTimestampSeconds);

                if (currentTimestampSeconds > adminTimestampSeconds) {
                    throw new Error('Invalid UNIX timestamp. Please provide a time in the future. We cannot create an election in the past. The current timestamp in seconds is: ' + currentTimestampSeconds);
                }

                console.log("Successfully passed the start time test.");

                // if (!endTime || typeof endTime !== 'string' || endTime < 0) {
                //     throw new Error('Invalid end time');
                // }
                if (!/^\d{10}$/.test(endTime)) {
                    throw new Error('Invalid UNIX timestamp. Please provide a valid numeric end time value greater than the current time in UNIX seconds time (10 digits).');
                }
                console.log("End time is: ", endTime);

                const minimumElectionDuration = 3600; // Minimum election duration in seconds (1 hour)
                const duration = endTime - startTime; // Calculate the duration in seconds
                if (duration < minimumElectionDuration) {
                    throw new Error('Invalid UNIX timestamp. The election has to last at least 1 hour.');
                }
                console.log("Successfully passed the end time test.");

                // Convert candidates to JSON string
                console.log("Successfully converted candidates to JSON string.");
                console.log("candidates not stringified to JSON ", candidates);

                const parsedCandidates = JSON.stringify(candidates);
                console.log("Parsed candidates:", parsedCandidates);


                result = await contract.submitTransaction(fcn, electionID, parsedCandidates, startTime, endTime);
                await gateway.disconnect();

                let response = {
                    message: message,
                    result
                }
                return response;
            } else {
                throw new Error('Only admin can create an election');
            }
        } else {
            message = `
                        Invalid Invocation.
                        `;
            let response = {
                message: message,
            }
            return response;
        }

    } catch (error) {
        console.log(`
                        Getting error: $ { error.message }
                        `)
        if (error.message.includes('Candidate already exists')) {
            return 'Candidate already exists';
        }
        if (error.message.includes('The voter has already voted in this election.')) {
            return 'The voter has already voted in this election.';
        }
        if (error.message.includes('Election already exists')) {
            return 'Election already exists';
        }
        if (error.message.includes('Election not found')) {
            return 'Election does not exist';
        }
        if (error.message.includes('Voting has not started yet for this election.')) {
            return 'Voting has not started yet for this election.';
        }
        if (error.message.includes('Voting has ended for this election.')) {
            return 'Voting has ended for this election.';
        }
        if (error.message.includes('Candidate not found in the specified election')) {
            return 'Candidate not found in the specified election';
        }
        if (error.message.includes('Voter not found.')) {
            return 'Voter not found.';
        }
        if (error.message.includes('The voter\'s school does not match the candidate\'s school.')) {
            return 'The voter\'s school does not match the candidate\'s school.';
        }
        if (error.message.includes('Freshman or Sophomore cannot vote for Junior or Senior candidates.')) {
            return 'Freshman or Sophomore cannot vote for Junior or Senior candidates.';
        }
        if (error.message.includes('Junior or Senior cannot vote for Freshman or Sophomore candidates.')) {
            return 'Junior or Senior cannot vote for Freshman or Sophomore candidates.';
        }
        if (error.message.includes('Error parsing candidate data. ')) {
            return 'Error parsing candidate data. Please make sure of the candidates data.';
        }



        return error.message;
    }
}

exports.invokeTransaction = invokeTransaction;
