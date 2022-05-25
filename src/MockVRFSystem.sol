// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockVRFSystem {
    uint256 public requestId;
    address public fekikiClub;

    function requestRandomWords(
        bytes32, /* keyHash */
        uint64, /* subId */
        uint16, /* minimumRequestConfirmations */
        uint32, /* callbackGasLimit */
        uint32 /* numWords */
    ) external returns (uint256) {
        return ++requestId;
    }

    function setFekikiClub(address _fekikiClub) external {
        fekikiClub = _fekikiClub;
    }

    function completeRequest(uint256 _requestId, uint256[] memory _randomWords) external {
        (bool success, ) = fekikiClub.call(
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("rawFulfillRandomWords(uint256,uint256[])"))),
                _requestId,
                _randomWords
            )
        );
        require(success, "callback failed");
    }
}
