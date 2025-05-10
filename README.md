# Ethereum Advanced - Random Number Generation for NFT Creation

## Descrizione del progetto

Questo progetto è una soluzione basata su Ethereum che utilizza il **Chainlink VRF** (Verifiable Random Function) per generare numeri casuali in modo sicuro e verificabile. Questi numeri casuali vengono utilizzati per creare **NFT** (Token Non Fungibili) unici, ciascuno con un attributo basato sul numero casuale generato, come ad esempio una **città**.

Il contratto smart sfrutta i numeri casuali per assegnare città ai NFT generati, permettendo la creazione di una collezione unica di NFT con attributi differenti basati su numeri casuali verificabili sulla blockchain.

## Funzionalità

- **Generazione di numeri casuali** sicuri e verificabili tramite Chainlink VRF.
- Creazione di **NFT unici** con attributi basati sui numeri casuali.
- **Controllo sulla supply** degli NFT e possibilità per il proprietario del contratto di aggiornare il costo di minting e la supply massima.
- **Compatibilità con Hardhat** per il testing locale.

## Come funziona

1. **Minting di un NFT**: l'utente paga una piccola quota di Ether e il contratto genera un numero casuale tramite Chainlink VRF.
2. **Attribuzione dell'attributo**: il numero casuale viene utilizzato per determinare un attributo unico dell'NFT, come una **città**.
3. **Generazione del Token**: l'NFT viene creato e un URI di metadati viene assegnato per fornire informazioni come il nome, la descrizione e l'attributo specifico (ad esempio, città).
4. **Gestione della Supply**: l'owner del contratto può aggiornare il costo di minting e la supply massima degli NFT.

## Installazione

Segui questi passaggi per eseguire il progetto localmente:

1. **Clona il repository**:

   ```bash
   git clone https://github.com/JacopoCarrozzo/Ethereum-Advanced.git
   cd Ethereum-Advanced
