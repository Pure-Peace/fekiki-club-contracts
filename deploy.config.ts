/* eslint-disable @typescript-eslint/no-unused-vars */
import {BigNumber, BigNumberish} from 'ethers';
import {parseEther} from 'ethers/lib/utils';
import {
  ChainlinkConfigStruct,
  FekikiConfigStruct,
} from './typechain/FekikiClub';

// eslint-disable-next-line @typescript-eslint/ban-types
export type DeployConfig = {
  vrfCoordinator: string;
  chainlinkConfig: ChainlinkConfigStruct;
  fekikiConfig: FekikiConfigStruct;
};

const toTokenAmount = (amount: BigNumberish, tokenDecimal: BigNumberish) => {
  return BigNumber.from(amount).mul(BigNumber.from(10).pow(tokenDecimal));
};

const config: {[key: string]: DeployConfig} = {
  mainnet: {
    vrfCoordinator: '',
    chainlinkConfig: {
      keyHash: '',
      subscriptionId: 0,
      requestConfirms: 0,
      callbackGasLimit: 0,
    },
    fekikiConfig: {
      merkleRootHash: '',
      unitPrice: parseEther('1'),
      maxSupply: 10000,
      pubMintReserve: 1000,
      devReserve: 180,
      whiteListSupply: 7810,
      personalPubMintLimit: 1,
      personalWhitelistMintLimit: 2,
      revealedTokenUri: '',
      mysteryBoxUri: '',
      commonTokenUri: '',
    },
  },
  rinkeby: {
    vrfCoordinator: '0x6168499c0cffcacd319c818142124b7a15e857ab',
    chainlinkConfig: {
      keyHash:
        '0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc',
      subscriptionId: 4811,
      requestConfirms: 3,
      callbackGasLimit: 100000,
    },
    fekikiConfig: {
      merkleRootHash:
        '0x50ecc22abb1fa8080de47f7197930887fb1aa617c461969163d3e4c40ca18926',
      unitPrice: parseEther('0.0000001'),
      maxSupply: 20,
      pubMintReserve: 4,
      devReserve: 10,
      whiteListSupply: 6,
      personalPubMintLimit: 1,
      personalWhitelistMintLimit: 2,
      revealedTokenUri:
        'https://gateway.pinata.cloud/ipfs/QmXs2iu4y9tawjUHmvUxwCce4DCL8xeC9dYMgUvQbUXjFk/',
      mysteryBoxUri:
        'https://gateway.pinata.cloud/ipfs/QmdRW358Yk9R7o95KHvUgwVKC4XMgXo8viQmZX5rnEJ4TQ/',
      commonTokenUri: '',
    },
  },
  hardhat: {
    vrfCoordinator: '',
    chainlinkConfig: {
      keyHash:
        '0x0000000000000000000000000000000000000000000000000000000000000000',
      subscriptionId: 0,
      requestConfirms: 0,
      callbackGasLimit: 0,
    },
    fekikiConfig: {
      merkleRootHash:
        '0x0000000000000000000000000000000000000000000000000000000000000000',
      unitPrice: parseEther('0'),
      maxSupply: 1000,
      pubMintReserve: 0,
      devReserve: 1000,
      whiteListSupply: 0,
      personalPubMintLimit: 0,
      personalWhitelistMintLimit: 0,
      revealedTokenUri: '',
      mysteryBoxUri: '',
      commonTokenUri: '',
    },
  },
};

export default config;
