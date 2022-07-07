import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { genGetContractWith } from '../test/utils/genHelpers';
import { FekikiClub } from '../typechain/FekikiClub';
import { deployConfig, waitContractCall } from '../scripts/utils';
import { getContractForEnvironment } from '../test/utils/getContractForEnvironment';
import { MockVRFSystem as IMockVRFSystem, TestFekikiClub } from '../typechain';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();
  const {
    vrfCoordinator,
    chainlinkConfig,
    merkleRootHash
  } = deployConfig();

  if (hre.network.name === 'hardhat') {
    const MockVRFSystem = await getContractForEnvironment<IMockVRFSystem>(hre, "MockVRFSystem")

    const fekikiDeployments = await deploy('TestFekikiClub', {
      from: deployer,
      contract: 'TestFekikiClub',
      args: [MockVRFSystem.address, chainlinkConfig, merkleRootHash],
      log: true,
      skipIfAlreadyDeployed: false,
      gasLimit: 5500000,
    });
    await waitContractCall(await MockVRFSystem.setFekikiClub(fekikiDeployments.address))

    return
  }

  const fekikiDeployments = await deploy('FekikiClub', {
    from: deployer,
    contract: 'FekikiClub',
    args: [vrfCoordinator, chainlinkConfig, merkleRootHash],
    log: true,
    skipIfAlreadyDeployed: false,
    gasLimit: 5500000,
  });
  const { getContractAt } = genGetContractWith(hre);
  const fekikiClub = await getContractAt<FekikiClub>(
    'FekikiClub',
    fekikiDeployments.address,
    deployer
  );
};
export default func;
func.id = 'deploy_fekiki_club';
func.tags = ['FekikiClub'];
