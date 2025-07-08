# Ethereum Advanced - Random Number Generation for NFT Creation

## Project Description

This project is an Ethereum-based solution that uses **Chainlink VRF** (Verifiable Random Function) to generate random numbers in a secure and verifiable way. These random numbers are used to create unique **NFTs** (Non-Fungible Tokens), each with an attribute based on the generated random number, such as a **city**.

The smart contract uses the random numbers to assign cities to the generated NFTs, allowing the creation of a unique collection of NFTs with different attributes based on random numbers verifiable on the blockchain.

## Features

- **Secure and verifiable random number generation** via Chainlink VRF.
- Creation of unique **NFTs** with attributes based on random numbers.
- **Control over the supply** of NFTs and the ability for the contract owner to update the minting cost and maximum supply.
- **Hardhat compatibility** for local testing.

## How it works

1. **NFT Mining**: The user pays a small amount of Ether and the contract generates a random number via Chainlink VRF.
2. **Attribute Assignment**: The random number is used to determine a unique attribute of the NFT, such as a **city**.
3. **Token Generation**: The NFT is created and a metadata URI is assigned to provide information such as the name, description, and specific attribute (e.g., city).
4. **Supply Management**: The contract owner can update the minting cost and maximum supply of NFTs.
