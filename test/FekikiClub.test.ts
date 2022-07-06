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
import { TestFekikiClub as ITestFekikiClub, MockVRFSystem as IMockVRFSystem } from '../typechain';

const bn = (num: BigNumberish) => BigNumber.from(num)
const genArray = (start: number, length: number) => Array.from({ length }, (_, index) => index + start)
const random = () => bn((Math.random() * 100000000000).toFixed(0));
const genArrayRandom = (length: number) => Array.from({ length }, () => random())

const setup = deployments.createFixture(async () => {
  await deployments.fixture('MockVRFSystem');
  await deployments.fixture('FekikiClub');
  const contracts = {
    MockVRFSystem: await getContractForEnvironment<IMockVRFSystem>(hre, 'MockVRFSystem'),
    FekikiClub: await getContractForEnvironment<ITestFekikiClub>(hre, 'TestFekikiClub'),
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


describe('FekikiClub test', function () {
  it('Should mint 100 FEKIKI to address', async function () {
    const { users, FekikiClub } = await setup();

    const user = users.deployer.address;
    await FekikiClub.testMint(100, user)

    const balance = await FekikiClub.balanceOf(user)
    expect(balance, 'balance not 100').to.equal(bn(100));
  });

  it('Reveal 20 FEKIKI', async function () {
    const { users, FekikiClub, MockVRFSystem } = await setup();

    const AMOUNT = 20

    const user = users.deployer.address;
    await FekikiClub.testMint(AMOUNT, user)

    const requestId = (await MockVRFSystem.requestId()).add(1);
    await users.deployer.FekikiClub.requestTokenReveal(genArray(1, AMOUNT))
    await MockVRFSystem.completeRequest(requestId, genArrayRandom(AMOUNT))

    const revealedTokens = await FekikiClub.revealedTokensAmount()
    expect(revealedTokens, `Revealed tokens amount not ${AMOUNT}`).to.equal(bn(AMOUNT));
  });

  it('Test mintWhitelistAndReveal', async function () {
    const { users, FekikiClub, MockVRFSystem } = await setup();

    const MINT_AMOUNT = 1
    const PROOF: string[] = []

    const UNIT_PRICE = await FekikiClub.UNIT_PRICE()
    await users.deployer.FekikiClub.setWhiteListMintTime(0, 999999999999999)
    await users.deployer.FekikiClub.mintWhitelistAndReveal(MINT_AMOUNT, PROOF, { value: UNIT_PRICE.mul(MINT_AMOUNT) })

    const requestId = await MockVRFSystem.requestId()
    await MockVRFSystem.completeRequest(requestId, genArrayRandom(MINT_AMOUNT))

    const revealedTokens = await FekikiClub.revealedTokensAmount()
    expect(revealedTokens, `Revealed tokens amount not ${MINT_AMOUNT}`).to.equal(bn(MINT_AMOUNT));
  });
})
