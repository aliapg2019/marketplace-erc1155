Marketplace-ERC1155
-------------------

`Marketplace-ERC1155` is a decentralized marketplace for buying and selling ERC1155 tokens on the Ethereum blockchain. This repository contains the smart contracts and frontend code for the marketplace.

### Requirements

To run Marketplace-ERC1155, you'll need:

-   Node.js v12 or later
-   Truffle v5 or later
-   Ganache v2 or later
-   MetaMask browser extension

### Installation

1.  Clone the repository: `git clone https://github.com/aliapg2019/marketplace-erc1155.git`
2.  Install dependencies: `npm install`

### Setup

1.  Start Ganache: `ganache-cli`
2.  Compile the contracts: `truffle compile`
3.  Migrate the contracts to the local blockchain: `truffle migrate`
4.  Deploy the frontend: `npm run dev`
5.  Connect to your local blockchain using MetaMask

### Usage

To use Marketplace-ERC1155, you can buy or sell ERC1155 tokens on the marketplace.

The contracts are located in `contracts/`. You can find their ABIs in `build/contracts/`.

### Contributing

If you find a bug or have an idea for a new feature, feel free to submit an issue or pull request.

### License

Marketplace-ERC1155 is released under the [MIT License](https://github.com/aliapg2019/marketplace-erc1155/blob/main/LICENSE).

Smart Contracts
---------------

The `marketplace-erc1155` repository contains two smart contracts: `ERC1155Token` and `Marketplace`.

### ERC1155Token

The `ERC1155Token` is a smart contract that defines the behavior and properties of a multi-token contract. This contract is used to create and manage multiple fungible or non-fungible tokens that can be bought and sold on the marketplace.

### Marketplace

The `Marketplace` is a smart contract that manages the buying and selling of ERC1155 tokens on the marketplace. This contract allows users to list their tokens for sale, make bids on tokens that are for sale, and finalize transactions.

Frontend
--------

The `marketplace-erc1155` repository also contains frontend code for the marketplace. This code is built using React and Web3.js, and allows users to interact with the marketplace by listing tokens for sale, making bids, and finalizing transactions. The frontend code is located in the `client/` directory.
