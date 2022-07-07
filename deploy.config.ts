/* eslint-disable @typescript-eslint/no-unused-vars */
import { BigNumber, BigNumberish } from 'ethers';
import { ChainlinkConfigStruct } from './typechain/FekikiClub';

// eslint-disable-next-line @typescript-eslint/ban-types
export type DeployConfig = {
  vrfCoordinator: string;
  chainlinkConfig: ChainlinkConfigStruct,
  merkleRootHash: string;
};

const toTokenAmount = (amount: BigNumberish, tokenDecimal: BigNumberish) => {
  return BigNumber.from(amount).mul(BigNumber.from(10).pow(tokenDecimal));
};

const config: { [key: string]: DeployConfig } = {
  mainnet: {
    vrfCoordinator: '',
    chainlinkConfig: {
      keyHash: '',
      subscriptionId: 0,
      requestConfirms: 0,
      callbackGasLimit: 0
    },
    merkleRootHash: ''
  },
  rinkeby: {
    vrfCoordinator: '0x6168499c0cffcacd319c818142124b7a15e857ab',
    chainlinkConfig: {
      keyHash: '0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc',
      subscriptionId: 4811,
      requestConfirms: 3,
      callbackGasLimit: 1000000
    },
    merkleRootHash: '0x50ecc22abb1fa8080de47f7197930887fb1aa617c461969163d3e4c40ca18926'
  },
  hardhat: {
    vrfCoordinator: '',
    chainlinkConfig: {
      keyHash: '0x0000000000000000000000000000000000000000000000000000000000000000',
      subscriptionId: 0,
      requestConfirms: 0,
      callbackGasLimit: 0
    },
    merkleRootHash: '0x0000000000000000000000000000000000000000000000000000000000000000'
  },
};

export default config;
