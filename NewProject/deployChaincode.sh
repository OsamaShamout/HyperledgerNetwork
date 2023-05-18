export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export PEER0_ORG3_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/artifacts/channel/config/

export CHANNEL_NAME=mychannel

setGlobalsForOrderer(){
    export CORE_PEER_LOCALMSPID="OrdererMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp
    
}

setGlobalsForPeer0Org1(){
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

setGlobalsForPeer1Org1(){
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:8051
    
}

setGlobalsForPeer0Org2(){
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
    
}

setGlobalsForPeer1Org2(){
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:10051
    
}

setGlobalsForPeer0Org3(){
    export CORE_PEER_LOCALMSPID="Org3MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
    
}

setGlobalsForPeer1Org3(){
    export CORE_PEER_LOCALMSPID="Org3MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
    export CORE_PEER_ADDRESS=localhost:12051
    
}

presetup(){
  echo "Vendoring Go Dependencies"
  pushd ./chaincode/go/evote
  GO111MODULE=on go mod vendor
  popd
  echo Finished Vendoring Go Dependencies
}

# presetup

# presetup(){
#     echo Vendoring Go dependencies ...
#     pushd ./artifacts/src/github.com/fabcar_contract_api/go
#     GO111MODULE=on go mod vendor
#     popd
#     echo Finished vendoring Go dependencies
# }


CHANNEL_NAME="mychannel"
CC_RUNTIME_LANGUAGE="golang"
VERSION="1"
CC_SRC_PATH=${PWD}/chaincode/go/evote
CC_NAME="evote"

packageChaincode() {
    rm -rf ${CC_NAME}.tar.gz
    setGlobalsForPeer0Org1
    echo $CORE_PEER_LOCALMSPID
    echo $CORE_PEER_TLS_ROOTCERT_FILE
    echo $CORE_PEER_MSPCONFIGPATH
    echo $CORE_PEER_ADDRESS 
    echo "===================== Packaging chaincode on peer0.org1 ===================== "
    echo $CC_SRC_PATH
    echo ${CC_NAME}
    peer lifecycle chaincode package ${CC_NAME}.tar.gz \
        --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} \
        --label ${CC_NAME}_${VERSION}
    echo $?
    echo "===================== Chaincode is packaged on peer0.org1 ===================== "
 
}


installChaincode() {
    setGlobalsForPeer0Org1
    echo $CORE_PEER_LOCALMSPID
    echo $CORE_PEER_TLS_ROOTCERT_FILE
    echo $CORE_PEER_MSPCONFIGPATH
    echo $CORE_PEER_ADDRESS 
    echo $CORE_CHAINCODE_JAVA_RUNTIME
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on peer0.org1 ===================== "

    setGlobalsForPeer1Org1
    echo $CORE_PEER_LOCALMSPID
    echo $CORE_PEER_TLS_ROOTCERT_FILE
    echo $CORE_PEER_MSPCONFIGPATH
    echo $CORE_PEER_ADDRESS 
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on peer1.org1 ===================== "

    setGlobalsForPeer0Org2
    echo $CORE_PEER_LOCALMSPID
    echo $CORE_PEER_TLS_ROOTCERT_FILE
    echo $CORE_PEER_MSPCONFIGPATH
    echo $CORE_PEER_ADDRESS 
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on peer0.org2 ===================== "

    setGlobalsForPeer1Org2
    echo $CORE_PEER_LOCALMSPID
    echo $CORE_PEER_TLS_ROOTCERT_FILE
    echo $CORE_PEER_MSPCONFIGPATH
    echo $CORE_PEER_ADDRESS 
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on peer1.org2 ===================== "

    setGlobalsForPeer0Org3
    echo $CORE_PEER_LOCALMSPID
    echo $CORE_PEER_TLS_ROOTCERT_FILE
    echo $CORE_PEER_MSPCONFIGPATH
    echo $CORE_PEER_ADDRESS 
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on peer0.org3 ===================== "

    setGlobalsForPeer1Org3
    echo $CORE_PEER_LOCALMSPID
    echo $CORE_PEER_TLS_ROOTCERT_FILE
    echo $CORE_PEER_MSPCONFIGPATH
    echo $CORE_PEER_ADDRESS 
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on peer1.org3 ===================== "
}


queryInstalled() {
     setGlobalsForPeer0Org1
     peer lifecycle chaincode queryinstalled >&log.txt
     echo $?
     cat log.txt
     PACKAGE_ID=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
     echo PackageID is ${PACKAGE_ID}
     export PACKAGE_ID=${PACKAGE_ID}
     echo "===================== Query installed successful on peer0.org1 on channel ===================== "
}

approveForMyOrg1(){
    echo $ORDERER_CA
    setGlobalsForPeer0Org1
    peer lifecycle chaincode approveformyorg -o localhost:7050  \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
    --channelID $CHANNEL_NAME --name ${CC_NAME} \
    --version ${VERSION} --init-required --package-id ${PACKAGE_ID} --sequence ${VERSION}

    echo "===================== chaincode approved from org 1 ===================== "
}

checkCommitReadiness() {
     setGlobalsForPeer0Org1
     peer lifecycle chaincode checkcommitreadiness \
         --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
         --sequence ${VERSION} --output json --init-required
     echo "===================== checking commit readiness from org 1 ===================== "
 }

approveForMyOrg2(){
    setGlobalsForPeer0Org2
    peer lifecycle chaincode approveformyorg -o localhost:7050  \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
    --channelID $CHANNEL_NAME --name ${CC_NAME} \
    --version ${VERSION} --init-required --package-id ${PACKAGE_ID} --sequence ${VERSION}

    echo "===================== chaincode approved from org 1 ===================== "
}

checkCommitReadiness() {

     setGlobalsForPeer0Org1
     peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
         --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
         --name ${CC_NAME} --version ${VERSION} --sequence ${VERSION} --output json --init-required
     echo "===================== checking commit readiness from org 1 ===================== "
 }

approveForMyOrg3(){
    setGlobalsForPeer0Org3
    peer lifecycle chaincode approveformyorg -o localhost:7050  \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
    --channelID $CHANNEL_NAME --name ${CC_NAME} \
    --version ${VERSION} --init-required --package-id ${PACKAGE_ID} --sequence ${VERSION}

    echo "===================== chaincode approved from org 1 ===================== "
}

checkCommitReadiness() {

     setGlobalsForPeer0Org1
     peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
         --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
         --name ${CC_NAME} --version ${VERSION} --sequence ${VERSION} --output json --init-required
     echo "===================== checking commit readiness from org 1 ===================== "
 }

commitChaincodeDefinition() {
     setGlobalsForPeer0Org1
     peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
         --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
         --channelID $CHANNEL_NAME --name ${CC_NAME} \
         --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
         --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA \
         --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_ORG3_CA \
         --version ${VERSION} --sequence ${VERSION} --init-required

    echo "===================== Chaincode Definition commited on peer0-org 1, peer0-org2, peer0-org3 ===================== "
}

queryCommitted(){
    setGlobalsForPeer0Org1

    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME}   
}



chaincodeInvokeInit(){
    setGlobalsForPeer0Org1

    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
    --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} \
    --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
    --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA \
    --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_ORG3_CA \
    --isInit -c '{"function":"InitLedger","Args":[]}'
    
}


chaincodeCreateUser(){
    setGlobalsForPeer0Org1
    ## Add vote
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.example.com \
        --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME}  \
        --peerAddresses localhost:7051 \
        --tlsRootCertFiles $PEER0_ORG1_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA $PEER_CONN_PARMS  \
        --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_ORG3_CA $PEER_CONN_PARMS  \
        -c '{"function": "RegisterUser","Args":["04", "Osama Mohammad"]}'
}

chaincodeVote(){    
    setGlobalsForPeer0Org1
    
    ## Add vote
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.example.com \
        --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME}  \
        --peerAddresses localhost:7051 \
        --tlsRootCertFiles $PEER0_ORG1_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA $PEER_CONN_PARMS  \
        --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_ORG3_CA $PEER_CONN_PARMS  \
        -c '{"function": "Vote","Args":["Election512", "id3", "wtf"]}'
}

chaincodeQuery(){
    setGlobalsForPeer0Org1
    # Query all Cars
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["GetElectionResults", "Election0"]}'
}

presetup
packageChaincode
installChaincode
queryInstalled
approveForMyOrg1
checkCommitReadiness
approveForMyOrg2
checkCommitReadiness
approveForMyOrg3
checkCommitReadiness
commitChaincodeDefinition
queryCommitted
chaincodeInvokeInit
#chaincodeCreateUser
#chaincodeVote
#chaincodeQuery
