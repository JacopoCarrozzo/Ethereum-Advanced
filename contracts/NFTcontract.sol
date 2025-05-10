// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol"; 
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "./utils/Base64.sol";

struct CityData {
    string city;
    string description;
}

contract NFTcontract is ERC721, VRFConsumerBaseV2Plus {

    using Counters for Counters.Counter;
    Counters.Counter public _tokenIdCounter;

    CityData[] private cities;
    mapping(uint256 => uint256) private tokenIdToCityIndex; 

    address private immutable vrfCoordinator;
    bytes32 private immutable s_keyHash;
    uint32 private immutable callbackGasLimit;
    uint32 private immutable numWords;
    uint64 private immutable s_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    mapping(uint256 => uint256) private _requestIdToTokenId;
    mapping(uint256 => uint256) private _randomNumbers;

    uint256 public mintingCost;
    uint256 public maxSupply;
    uint256 private constant UNSET = type(uint256).max;

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => bool) private _requestIdFulfilled;
    mapping(uint256 => string) private _tokenNames;
    mapping(uint256 => string) private _tokenDescriptions;
    mapping(uint256 => string) private _tokenCities;
    mapping(uint256 => uint256) private _tokenLuckyNumbers;
    mapping(uint256 => string) private _tokenTourChances;

    event RandomNumberRequested (uint256 indexed tokenId, uint256 requestId);
    event RandomNumberFulfilled (uint256 indexed tokenId, uint256 randomNumber);
    event TokenMinted (uint256 indexed tokenId);
    event DebugRequestId(uint256 requestId);
    event NFTMetadata(uint256 indexed tokenId,string name,string description,string city,string luckyNumber,string tourChance);

    constructor(
    address vrfCoordinator_,      
    bytes32 keyHash_,             
    uint32 callbackGasLimit_,     
    uint32 numWords_,             
    string memory name_,
    string memory symbol_,
    uint64 subscriptionId_,      
    uint256 initialMintingCost,
    uint256 initialMaxSupply
)
    ERC721(name_, symbol_)
    VRFConsumerBaseV2Plus(vrfCoordinator_)
{
 
    vrfCoordinator   = vrfCoordinator_;
    s_keyHash        = keyHash_;
    callbackGasLimit = callbackGasLimit_;
    numWords         = numWords_;
    s_subscriptionId = subscriptionId_;

    mintingCost = initialMintingCost;
    maxSupply   = initialMaxSupply;

    _tokenIdCounter.increment();

    cities.push(CityData("Berlin", "The cosmopolitan capital of Germany, rich in history and culture."));
    cities.push(CityData("Paris", "The city of love and fashion, with iconic landmarks and a romantic atmosphere."));
    cities.push(CityData("Rome", "The Eternal City, the cradle of Western civilization with ancient ruins and extraordinary art."));
    cities.push(CityData("Madrid", "The vibrant capital of Spain, famous for its energy, art, and delicious cuisine."));
    cities.push(CityData("Amsterdam", "Known for its picturesque canals, narrow houses, and relaxed atmosphere."));
    cities.push(CityData("Frankfurt", "A major financial center with a mix of modern and traditional architecture."));
    cities.push(CityData("London", "A historic and multicultural metropolis with world-famous attractions."));
    cities.push(CityData("Dublin", "The lively capital of Ireland, famous for its music, cozy pubs, and literary history."));
    cities.push(CityData("Brussels", "The heart of Europe, home to important institutions and famous for chocolate and beer."));
    cities.push(CityData("Zurich", "An elegant and clean Swiss city, known for its high quality of life and picturesque lake."));
    cities.push(CityData("Milan", "The Italian capital of fashion and design, with a rich artistic and cultural history."));
    cities.push(CityData("Marseille", "A dynamic port city in the south of France with a unique culture and a rich maritime heritage."));
    cities.push(CityData("Vienna", "The elegant capital of Austria, famous for its classical music, coffee houses, and imperial architecture."));
    cities.push(CityData("Prague", "A charming Bohemian city with a well-preserved historic center and a magical atmosphere."));
    cities.push(CityData("Barcelona", "A cosmopolitan Spanish city famous for its modernist architecture, beaches, and vibrant nightlife."));
    cities.push(CityData("Florence", "The birthplace of the Italian Renaissance, with artistic masterpieces and breathtaking architecture."));
    cities.push(CityData("Rotterdam", "A modern port city in the Netherlands with innovative architecture and a dynamic atmosphere."));
    cities.push(CityData("Copenhagen", "The Danish capital with a high quality of life, famous for design, bicycles, and a cozy atmosphere."));
    cities.push(CityData("Stockholm", "The beautiful capital of Sweden, built on several islands with elegant buildings and parks."));
    cities.push(CityData("Oslo", "The Norwegian capital surrounded by fjords and forests, with a rich Viking history and interesting museums."));
    cities.push(CityData("Helsinki", "The Finnish capital with a distinctive design, traditional saunas, and a strong connection to nature."));
    cities.push(CityData("Reykjavik", "The northernmost capital in the world, a gateway to Iceland's breathtaking landscapes."));
    cities.push(CityData("Naples", "A vibrant and passionate Italian city, famous for its pizza, ancient history, and unique atmosphere."));
    cities.push(CityData("Athens", "The historic capital of Greece, the birthplace of democracy and rich in ancient monuments."));
    cities.push(CityData("Mannheim", "Known for its grid layout, baroque palace, and strategic location at the confluence of two rivers."));
}
    function totalMinted() public view returns (uint256) {
    return _tokenIdCounter.current();
  }

    function requestRandomNumber() public payable {
        require(msg.value >= mintingCost, "Ether inviato insufficiente");
        require(_tokenIdCounter.current() <= maxSupply, "Raggiunta la fornitura massima di NFT");


        uint256 currentTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, currentTokenId);
        _randomNumbers[currentTokenId] = UNSET;

        uint256 requestId;
    try s_vrfCoordinator.requestRandomWords(
        VRFV2PlusClient.RandomWordsRequest({
            keyHash: s_keyHash,
            subId: s_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            extraArgs: VRFV2PlusClient._argsToBytes(
            VRFV2PlusClient.ExtraArgsV1({ nativePayment: false })
            )
        })

         ) returns (uint256 rid) {
            requestId = rid;
    } catch {
        requestId = VRFCoordinatorV2Interface(vrfCoordinator).requestRandomWords(
             s_keyHash,
             s_subscriptionId,
             REQUEST_CONFIRMATIONS,
             callbackGasLimit,
             numWords
           );
    }
    

        _requestIdToTokenId[requestId] = currentTokenId;
        _requestIdFulfilled[requestId] = false;

        emit RandomNumberRequested(currentTokenId, requestId);
        emit DebugRequestId(requestId);

    }


    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override{
        require(_requestIdToTokenId[requestId] > 0, "Richiesta non valida ");
        require(!_requestIdFulfilled[requestId], "Richiesta eseguita");
        require(randomWords.length > 0, "Nessun numero casuale ricevuto");

        uint256 tokenId = _requestIdToTokenId[requestId];
        uint256 randomNumber = randomWords[0] % 25;
        _randomNumbers[tokenId] = randomNumber;
        _requestIdFulfilled[requestId] = true;

        string memory name = string(abi.encodePacked("City NFT #", Strings.toString(tokenId)));
        (string memory city, string memory description) = getCityAndDescription(randomNumber);
        string memory luckyNumber = Strings.toString(randomNumber);
        string memory tourChance = (randomNumber == 7 ? "Yes" : "No");

         _tokenNames[tokenId] = name;
        _tokenDescriptions[tokenId] = description;
        _tokenCities[tokenId] = city;
        _tokenLuckyNumbers[tokenId] = randomNumber;
        _tokenTourChances[tokenId] = tourChance;

        string memory json = string(abi.encodePacked(
        '{"name":"', name,
        '", "description":"', description,
        '", "City":"', city,
        '", "Lucky Number":"', luckyNumber,
        '", "Tour Chance":"', tourChance,
        '"}'
        ));

        string memory base64 = Base64.encode(bytes(json));
        string memory tokenUri = string(abi.encodePacked("data:application/json;base64,", base64));
        _tokenURIs[tokenId] = tokenUri;

        emit NFTMetadata(tokenId, name, description, city, luckyNumber, tourChance);
        emit RandomNumberFulfilled(tokenId, randomNumber);
        emit TokenMinted(tokenId);
        
    }

    function tokenURI (uint256 tokenId) public view override returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) {revert("Token non esistente"); }
        require (_randomNumbers[tokenId] != UNSET, "Metadati non ancora generati");
        return _tokenURIs[tokenId];
    }

    function getRandomNumber(uint256 tokenId) public view returns (uint256) {
        if (_ownerOf(tokenId) == address(0)) revert("Token non esistente");
       require(_randomNumbers[tokenId] != UNSET, "Numero non ancora generato");
       return _randomNumbers[tokenId];
    }

    function getCityAndDescription(uint256 randomNumber) internal view returns (string memory city, string memory description) {
    require(randomNumber < cities.length, "Numero casuale non valido");
    CityData memory data = cities[randomNumber];
    return (data.city, string(abi.encodePacked("A unique NFT representing the city of ", data.city, ". ", data.description)));
    }

    function getTokenMetadata(uint256 tokenId) public view returns (string memory name, string memory description, string memory city, string memory luckyNumber, string memory tourChance) {
        if (_ownerOf(tokenId) == address(0)) {
        revert("Token non esistente");
        }
        require(_randomNumbers[tokenId] != UNSET, "Metadati non ancora generati");

        name = _tokenNames[tokenId];
    description = _tokenDescriptions[tokenId];
    city = _tokenCities[tokenId];
    luckyNumber = Strings.toString(_tokenLuckyNumbers[tokenId]);
    tourChance = _tokenTourChances[tokenId];
    }

    function _getStringValue(bytes memory jsonData, string memory key) internal pure returns (string memory) {
        bytes memory keyBytes = bytes(string(abi.encodePacked('"', key, '"')));
        uint256 start = find(jsonData, keyBytes);
        if (start == 0) {
        return "";
        }
        start += keyBytes.length;
        bytes memory colonBytes = bytes(":");
        start = find(jsonData, colonBytes, start);
        if (start == 0) {
        return "";      
        }
        start += colonBytes.length;
        bytes memory quoteBytes = bytes('"');
        start = find(jsonData, quoteBytes, start);
        if (start == 0) {
        return "";
        }
        start++;
        uint256 end = find(jsonData, quoteBytes, start);
        if (end == 0) {
        return "";
        }
        return string(slice(jsonData, start, end - start));
        }

    function find(bytes memory haystack, bytes memory needle, uint256 offset) internal pure returns (uint256) {
        for (uint256 i = offset; i <= haystack.length - needle.length; i++) {
        bool found = true;
        for (uint256 j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) {
        found = false;
        break;
        }
    }
        if (found) {
        return i;
    }
        }
    return 0;
    }

    function find(bytes memory haystack, bytes memory needle) internal pure returns (uint256) {
        return find(haystack, needle, 0);
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        bytes memory temp = new bytes(_length);
        for (uint256 i = 0; i < _length; i++) {
        temp[i] = _bytes[_start + i];
        }
        return temp;
    }

    function substring(string memory str, uint256 start, uint256 len) internal pure returns (string memory) {    
        bytes memory b = bytes(str);
        bytes memory temp = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
        temp[i] = b[start + i];
        }
        return string(temp);
    }

    function setMintingCost(uint256 newCost) public onlyOwner {
        mintingCost = newCost;
    }

    function getMintingCost() public view returns (uint256) {
        return mintingCost;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

}