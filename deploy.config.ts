/* eslint-disable @typescript-eslint/no-unused-vars */
import { BigNumber, BigNumberish } from 'ethers';
import { ChainlinkConfigStruct } from './typechain/FekikiClub';

// eslint-disable-next-line @typescript-eslint/ban-types
export type DeployConfig = {
  vrfCoordinator: string;
  chainlinkConfig: ChainlinkConfigStruct
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
    }
  },
  rinkeby: {
    vrfCoordinator: '',
    chainlinkConfig: {
      keyHash: '',
      subscriptionId: 0,
      requestConfirms: 0,
      callbackGasLimit: 0
    }
  },
  hardhat: {
    vrfCoordinator: '',
    chainlinkConfig: {
      keyHash: '0x0000000000000000000000000000000000000000000000000000000000000000',
      subscriptionId: 0,
      requestConfirms: 0,
      callbackGasLimit: 0
    }
  },
};

export default config;
