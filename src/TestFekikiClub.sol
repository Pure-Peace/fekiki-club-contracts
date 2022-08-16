// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FekikiClub.sol";

/** @dev Wrapper of FekikiClub for test */
contract TestFekikiClub is FekikiClub {
    constructor(
        address _vrfCoordinator,
        ChainlinkConfig memory _chainlinkConfig,
        bytes32 merkleRootHash,
        uint256 unitPrice,
        uint256 maxSupply,
        uint256 pubMintReserve,
        uint256 devReserve,
        uint256 whiteListSupply,
        uint256 personalPubMintLimit,
        uint256 personalWhitelistMintLimit
    )
        FekikiClub(
            _vrfCoordinator,
            _chainlinkConfig,
            merkleRootHash,
            unitPrice,
            maxSupply,
            pubMintReserve,
            devReserve,
            whiteListSupply,
            personalPubMintLimit,
            personalWhitelistMintLimit
        )
    {}

    function testMint(uint256 _amount, address _to) external supplyChecker(_amount) {
        _safeMint(_to, _amount);
    }
}
