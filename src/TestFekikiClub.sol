// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FekikiClub.sol";

/** @dev Wrapper of FekikiClub for test */
contract TestFekikiClub is FekikiClub {
    constructor(
        address _vrfCoordinator,
        ChainlinkConfig memory _chainlinkConfig,
        FekikiConfig memory _cfg
    ) FekikiClub(_vrfCoordinator, _chainlinkConfig, _cfg) {}

    function testMint(uint256 _amount, address _to) external supplyChecker(_amount) {
        _safeMint(_to, _amount);
    }
}
