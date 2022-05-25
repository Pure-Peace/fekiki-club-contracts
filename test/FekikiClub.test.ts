import { expect } from './chai-setup';
import * as hre from 'hardhat';
import {
  deployments,
  ethers,
  getNamedAccounts,
  getUnnamedAccounts,
} from 'hardhat';

import { setupUser, setupUsers, setupUsersWithNames } from './utils';
import { getContractForEnvironment } from './utils/getContractForEnvironment';
import { BigNumber, BigNumberish } from '@ethersproject/bignumber';
import { FekikiClub as IFekikiClub, MockVRFSystem as IMockVRFSystem } from '../typechain';

const bn = (num: BigNumberish) => BigNumber.from(num)

const setup = deployments.createFixture(async () => {
  await deployments.fixture('MockVRFSystem');
  await deployments.fixture('FekikiClub');
  const contracts = {
    MockVRFSystem: await getContractForEnvironment<IMockVRFSystem>(hre, 'MockVRFSystem'),
    FekikiClub: await getContractForEnvironment<IFekikiClub>(hre, 'FekikiClub'),
  };
  const users = await setupUsersWithNames((await getNamedAccounts()) as any, contracts);
  return {
    ...contracts,
    users,
  };
});


describe('MockVRFSystem test', function () {
  it('MockVRFSystem has been setup', async function () {
    const { MockVRFSystem, FekikiClub } = await setup();
    const requestId = await MockVRFSystem.requestId()
    expect(requestId, 'initial requestId should be 0').to.equal(bn(0));

    const fekikiClubAddress = await MockVRFSystem.fekikiClub()
    expect(fekikiClubAddress, `invalid fekikiClub address "${fekikiClubAddress}"`).to.equal(FekikiClub.address);
  });

})
