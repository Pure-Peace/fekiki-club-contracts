import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { genGetContractWith } from '../test/utils/genHelpers';
import { FekikiClub } from '../typechain/FekikiClub';
import { deployConfig } from '../scripts/utils';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();
  const {
    vrfCoordinator,
    chainlinkConfig
  } = deployConfig();

  const fekikiDeployments = await deploy('FekikiClub', {
    from: deployer,
    contract: 'FekikiClub',
    args: [vrfCoordinator, chainlinkConfig],
    log: true,
    skipIfAlreadyDeployed: false,
    gasLimit: 5500000,
  });
  const { getContractAt } = genGetContractWith(hre);
  const fekiki = await getContractAt<FekikiClub>(
    'FekikiClub',
    fekikiDeployments.address,
    deployer
  );
};
export default func;
func.id = 'deploy_fekiki_club';
func.tags = ['FekikiClub'];
