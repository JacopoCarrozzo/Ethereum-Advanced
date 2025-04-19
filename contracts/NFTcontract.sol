// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//npx hardhat run scripts/deploy.ts --network sepolia

//NFTContract deployed to: 0xfCbf569Caa096ec17D53f0249f2D069Dc0A6e06b

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol"; 
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/dev/vrf/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/dev/vrf/libraries/VRFV2PlusClient.sol";


contract NFTcontract is ERC721, VRFConsumerBaseV2Plus {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

   
    uint256 private immutable s_subscriptionId;
    address vrfCoordinator = 0x8103B0a8A00bE2DdC778e7E6CF055242F5874D24;
    bytes32 private constant s_keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint32 callbackGasLimit = 40000;
    uint16 private constant requestConfirmations = 3;
    uint32 numWords =  1;

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) private _randomNumbers;
    mapping(uint256 => bool) private _requestIdFulfilled;
    mapping(uint256 => uint256) private _requestIdToTokenId;

    event RandomNumberRequested (uint256 indexed tokenId, uint256 requestId);
    event RandomNumberFulfilled (uint256 indexed tokenId, uint256 randomNumber);
    event TokenMinted (uint256 indexed tokenId);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 subscriptionId
        ) ERC721 (name_, symbol_) VRFConsumerBaseV2Plus(vrfCoordinator){
            s_subscriptionId = subscriptionId;
        }


    function requestRandomNumber() public{

        uint256 currentTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, currentTokenId);

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        _requestIdToTokenId[requestId] = currentTokenId;
        _requestIdFulfilled[requestId] = false;

        emit RandomNumberRequested(currentTokenId, requestId);

    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override{
        require(_requestIdToTokenId[requestId] > 0, "Richiesta non valida ");
        require(!_requestIdFulfilled[requestId], "Richiesta eseguita");
        require(randomWords.length > 0, "Nessun numero casuale ricevuto");

        uint256 tokenId = _requestIdToTokenId[requestId];
        uint256 randomNumber = randomWords[0];
        _randomNumbers[tokenId] = randomNumber;
        _requestIdFulfilled[requestId] = true;


        string memory newTokenURI = generateTokenURI(tokenId, randomNumber);
        _tokenURIs[tokenId] = newTokenURI;

        emit RandomNumberFulfilled(tokenId, randomNumber);
        emit TokenMinted(tokenId);
        
    }

    function tokenURI (uint256 tokenId) public view override returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) {revert("Token non esistente"); }
        require (_randomNumbers[tokenId] > 0, "Metadati non ancora generati");
        return _tokenURIs[tokenId];
    }

    function getRandomNumber (uint256 tokenId) public view returns (uint256){
        if (_ownerOf(tokenId) == address(0)) {revert("Token non esistente");}
        return _randomNumbers[tokenId];       
    }

    function generateTokenURI (uint256 tokenId, uint256 randomNumber) internal pure returns (string memory) {
        string memory name = string(abi.encodePacked("il Mio NFT#", Strings.toString(tokenId)));
        string memory description = "Un NFT unico con specifiche personalizzate generate da un numero casuale";

        string memory attribute1Value;
        string memory attribute2Value;

        if (randomNumber % 3 == 0){
            attribute1Value = "Tipo A";
        } else if (randomNumber % 3 == 1){
            attribute1Value = "Tipo B";
        } else {
            attribute1Value = "Tipo C";
        }

        attribute2Value = Strings.toString(randomNumber % 100);

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '", "description": "', description, '", "attributes": [',
            '{"trait_type": "Tipo", "value": "', attribute1Value, '"},',
            '{"trait_type": "Valore Random", "value": "', attribute2Value, '"}]}'
            
            ));

            return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));

    }
}