#!/bin/bash


echo "Destroy the network" 
echo $(pwd)
docker compose -f docker-compose-cli.yaml down -v
echo "removing the channel artifacts " 
sudo rm -rf channel-artifacts
echo "removing the crypto-config "
sudo rm -rf crypto-config