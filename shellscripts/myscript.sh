#!/bin/bash

docker stop $(docker ps -aq) & docker rm $(docker ps -aq)
docker compose -f docker-compose-cli.yaml up -d
docker compose -f docker-compose-cli.yaml down -v 

sudo rm -rf channel-artifacts

../bin/cryptogen generate \
    --config crypto-config.yaml \
    --output=crypto-config

# create genesis and channel tx
../bin/configtxgen -profile OrdererGenesis \
    -outputBlock ./channel-artifacts/genesis.block \
    -channelID channelorderergenesis

../bin/configtxgen -profile ChannelDemo \
    -outputCreateChannelTx ./channel-artifacts/channel.tx \
    -channelID channeldemo

# Set anchor peer 
../bin/configtxgen -profile ChannelDemo \
    -outputAnchorPeersUpdate ./channel-artifacts/Panha1Anchor.tx \
    -channelID channeldemo -asOrg Panha1MSP

../bin/configtxgen -profile ChannelDemo -outputAnchorPeersUpdate \
    ./channel-artifacts/Panha2Anchor.tx \
    -channelID channeldemo -asOrg Panha2MSP

docker compose -f docker-compose-cli.yaml up -d




# login to  Org1 
docker exec -e "CORE_PEER_LOCALMSPID=Panha1MSP" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/fabric-samples/panha-network/crypto-config/peerOrganizations/be1.panha-network.com/peers/peer0.be1.panha-network.com/tls/ca.crt" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/fabric-samples/panha-network/crypto-config/peerOrganizations/be1.panha-network.com/users/Admin@be1.panha-network.com/msp" -e "CORE_PEER_ADDRESS=peer0.be1.panha-network.com:7051" -it cli bash

# log in to Org2
docker exec -e "CORE_PEER_LOCALMSPID=Panha2MSP" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/fabric-samples/panha-network/crypto-config/peerOrganizations/be2.panha-network.com/peers/peer0.be2.panha-network.com/tls/ca.crt" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/fabric-samples/panha-network/crypto-config/peerOrganizations/be2.panha-network.com/users/Admin@be2.panha-network.com/msp" -e "CORE_PEER_ADDRESS=peer0.be2.panha-network.com:7051" -it cli bash


export ORDERER_CA=/opt/gopath/fabric-samples/panha-network/crypto-config/ordererOrganizations/panha-network.com/orderers/orderer.panha-network.com/msp/tlscacerts/tlsca.panha-network.com-cert.pem 

# create channel 
peer channel create -o orderer.panha-network.com:7050 -c channeldemo -f /opt/gopath/fabric-samples/panha-network/channel-artifacts/channel.tx --tls  --cafile $ORDERER_CA

peer channel join -b channeldemo.block --tls --cafile $ORDERER_CA