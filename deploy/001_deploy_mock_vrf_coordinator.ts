import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { genGetContractWith } from '../test/utils/genHelpers';
import { FekikiClub } from '../typechain/FekikiClub';
import { deployConfig } from '../scripts/utils';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  if (hre.network.name === 'hardhat') {
    console.log('hardhat env, should deploy MockVRFSystem.')

    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;

    const { deployer } = await getNamedAccounts();

    const MockVRFSystemDeployments = await deploy('MockVRFSystem', {
      from: deployer,
      contract: 'MockVRFSystem',
      args: [],
      log: true,
      skipIfAlreadyDeployed: false,
      gasLimit: 5500000,
    });
  }
};
export default func;
func.id = 'deploy_mock_vrf_system';
func.tags = ['MockVRFSystem'];
