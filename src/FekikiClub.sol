// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FekikiClub is ERC721A, Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    using Strings for uint256;

    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    event RevealRequested(uint256 indexed tokenId, uint256 requestId);
    event Revealed(uint256 indexed tokenId, uint256 revealId);

    struct ChainlinkConfig {
        bytes32 keyHash;
        uint64 subscriptionId;
        uint16 requestConfirms;
        uint32 callbackGasLimit;
    }

    // Compiler will pack this into a single 256bit word.
    struct UserMintedData {
        uint128 whitelist;
        uint128 pubMint;
    }

    // Compiler will pack this into a single 256bit word.
    struct RevealData {
        // request sequence
        uint168 requestSeq;
        uint64 revealId;
        // request flag
        bool requested;
    }

    mapping(uint256 => uint256) private _tokenIdMapInner;
    mapping(uint256 => RevealData) private _tokenRevealData; // tokenId => RevealData
    mapping(uint256 => uint16[]) private _tokenRevealRequest; // requestId => tokenIdList
    mapping(address => UserMintedData) private _userMinted; // address => NumberMintedData

    uint256 public immutable UNIT_PRICE;

    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable PUB_MINT_RESERVE;
    uint256 public immutable DEV_RESERVE;
    uint256 public immutable WHITELIST_MINTING_SUPPLY;

    uint256 public immutable PERSONAL_PUB_MINT_LIMIT;
    uint256 public immutable PERSONAL_WHITELIST_MINT_LIMIT;

    uint256 public WHITELIST_MINTING_START;
    uint256 public WHITELIST_MINTING_END;

    bytes32 public immutable MERKLE_ROOT_HASH;
    VRFCoordinatorV2Interface public immutable VRF_COORDINATOR;
    ChainlinkConfig public chainlinkConfig;

    uint256 public revealedTokensAmount;
    uint256 public numberMintedDevTeam;
    uint256 public numberWhitelistMinted;
    uint256 public numberPublicMinted;

    // When the PUB_MINT_SUPPLY is 0, it means that public minting has not started.
    uint256 public PUB_MINT_SUPPLY;

    constructor(
        address _vrfCoordinator, // Chainlink VRF coordinator address
        ChainlinkConfig memory _chainlinkConfig,
        bytes32 merkleRootHash,
        uint256 unitPrice,
        uint256 maxSupply,
        uint256 pubMintReserve,
        uint256 devReserve,
        uint256 whiteListSupply,
        uint256 personalPubMintLimit,
        uint256 personalWhitelistMintLimit
    ) ERC721A("FekikiClub", "FEKIKI") VRFConsumerBaseV2(_vrfCoordinator) {
        UNIT_PRICE = unitPrice;
        MAX_SUPPLY = maxSupply;
        PUB_MINT_RESERVE = pubMintReserve;
        DEV_RESERVE = devReserve;
        WHITELIST_MINTING_SUPPLY = whiteListSupply;
        PERSONAL_PUB_MINT_LIMIT = personalPubMintLimit;
        PERSONAL_WHITELIST_MINT_LIMIT = personalWhitelistMintLimit;
        require(
            PUB_MINT_RESERVE + DEV_RESERVE + WHITELIST_MINTING_SUPPLY == MAX_SUPPLY,
            "Incorrect quantity configuration"
        );
        VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        chainlinkConfig = _chainlinkConfig;
        MERKLE_ROOT_HASH = merkleRootHash;
    }

    modifier supplyChecker(uint256 amount) {
        require((totalSupply() + amount) <= MAX_SUPPLY, "Exceed max supply");
        _;
    }

    function _merkleVerify(bytes32[] calldata _merkleProof) private view {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, MERKLE_ROOT_HASH, leaf), "Merkle verify failed");
    }

    // FOR TEST
    function setWhiteListMintTime(uint256 start, uint256 end) external onlyOwner {
        WHITELIST_MINTING_START = start;
        WHITELIST_MINTING_END = end;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmXs2iu4y9tawjUHmvUxwCce4DCL8xeC9dYMgUvQbUXjFk/";
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        if (_tokenRevealData[_tokenId].revealId == 0) {
            return "https://gateway.pinata.cloud/ipfs/QmdRW358Yk9R7o95KHvUgwVKC4XMgXo8viQmZX5rnEJ4TQ/";
        }

        return string(abi.encodePacked(_baseURI(), uint256(_tokenRevealData[_tokenId].revealId).toString()));
    }

    function userMinted(address user) external view returns (UserMintedData memory) {
        return _userMinted[user];
    }

    /**
     * @dev Returns the number of tokens that have been mint.
     */
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /**
     * @dev Returns the number of tokens minted by the specified address.
     */
    function numberMinted(address _minter) external view returns (uint256) {
        return _numberMinted(_minter);
    }

    function tokenRevealData(uint256[] calldata _tokenIds) external view returns (RevealData[] memory) {
        RevealData[] memory data = new RevealData[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (!_exists(_tokenIds[i])) revert OwnerQueryForNonexistentToken();
            data[i] = _tokenRevealData[_tokenIds[i]];
        }
        return data;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _tokenIdMap(uint256 _tokenIndex) private view returns (uint256) {
        if (_tokenIdMapInner[_tokenIndex] == 0) {
            return _tokenIndex + 1;
        }
        return _tokenIdMapInner[_tokenIndex];
    }

    /**
     * @dev Allow the development team to modify the chainlink configuration.
     */
    function setChainlinkConfig(ChainlinkConfig memory _chainlinkConfig) external onlyOwner {
        chainlinkConfig = _chainlinkConfig;
    }

    /**
     * @dev Chainlink will call this function in the callback.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint16[] storage tokenIdSeq = _tokenRevealRequest[requestId];
        require(tokenIdSeq.length > 0, "Request not exists");
        require(randomWords.length == tokenIdSeq.length, "Array length mismatch");
        for (uint256 i = 0; i < tokenIdSeq.length; ) {
            require(
                _tokenRevealData[tokenIdSeq[i]].requested && _tokenRevealData[tokenIdSeq[i]].revealId == 0,
                "Not requested or already revealed"
            );

            uint256 randomIndex = (randomWords[_tokenRevealData[tokenIdSeq[i]].requestSeq] %
                (MAX_SUPPLY - revealedTokensAmount)) + revealedTokensAmount;
            uint256 revealId = _tokenIdMap(randomIndex);
            uint256 currentId = _tokenIdMap(revealedTokensAmount);

            _tokenIdMapInner[randomIndex] = currentId;
            _tokenRevealData[tokenIdSeq[i]].revealId = uint64(revealId);
            revealedTokensAmount += 1;

            emit Revealed(tokenIdSeq[i], revealId);
            unchecked {
                i++;
            }
        }
        _tokenRevealRequest[requestId] = new uint16[](0);
    }

    function withdraw(address payable _to) external payable onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success);
    }

    /**
     * @dev Allows the development team to mint the reserved amount of tokens.
     * @param _amount Minting amount of tokens.
     * @param _to Mint to target address.
     */
    function mintDevTeam(uint256 _amount, address _to) public onlyOwner supplyChecker(_amount) {
        numberMintedDevTeam += _amount;
        require(numberMintedDevTeam <= DEV_RESERVE, "Insufficient dev minting supply");
        _safeMint(_to, _amount);
    }

    /**
     * @dev Available after public minting starts.
     * @param _amount Minting amount of tokens.
     */
    function mint(uint256 _amount) public payable supplyChecker(_amount) {
        numberPublicMinted += _amount;
        require(numberPublicMinted <= PUB_MINT_SUPPLY, "Insufficient public minting supply");

        _userMinted[msg.sender].pubMint += uint128(_amount);
        require(_userMinted[msg.sender].pubMint <= PERSONAL_PUB_MINT_LIMIT, "Exceed personal pub minting limit");

        require(msg.value >= (_amount * UNIT_PRICE), "Underpayment");
        _safeMint(msg.sender, _amount);
    }

    /**
     * @dev Allows users to pass merkle proof `_merkleProof` to verify the whitelist
     * and pay the corresponding amount of ether for minting `_amount` of tokens.
     * Users can only call for a specified period,
     * once expired their whitelist will no longer be available.
     * @param _amount Minting amount of tokens.
     * @param _merkleProof Merkle tree proof corresponding to the user address (can be generated using javascript)
     */
    function mintWhitelist(uint256 _amount, bytes32[] calldata _merkleProof) public payable supplyChecker(_amount) {
        _merkleVerify(_merkleProof);
        require(
            (block.timestamp >= WHITELIST_MINTING_START) && block.timestamp <= WHITELIST_MINTING_END,
            "Whitelist minting not in progress"
        );

        numberWhitelistMinted += _amount;
        require(numberWhitelistMinted <= WHITELIST_MINTING_SUPPLY, "Insufficient whitelist minting supply");

        _userMinted[msg.sender].whitelist += uint128(_amount);
        require(
            _userMinted[msg.sender].whitelist <= PERSONAL_WHITELIST_MINT_LIMIT,
            "Exceed personal whitelist minting limit"
        );

        require(msg.value >= (_amount * UNIT_PRICE), "Underpayment");
        _safeMint(msg.sender, _amount);
    }

    /**
     * @dev Call `mintDevTeamAndReveal`, then reveal
     */
    function mintDevTeamAndReveal(uint256 _amount, address _to) external payable onlyOwner {
        uint256 _startIndex = _currentIndex;
        mintDevTeam(_amount, _to);
        revealWithRange(_startIndex, _amount);
    }

    /**
     * @dev Call `mintWhitelist`, then reveal
     */
    function mintWhitelistAndReveal(uint256 _amount, bytes32[] calldata _merkleProof) external payable {
        uint256 _startIndex = _currentIndex;
        mintWhitelist(_amount, _merkleProof);
        revealWithRange(_startIndex, _amount);
    }

    /**
     * @dev Call `mint`, then reveal
     */
    function mintAndReveal(uint256 _amount) external payable {
        uint256 _startIndex = _currentIndex;
        mint(_amount);
        revealWithRange(_startIndex, _amount);
    }

    /**
     * @dev Reveal with token id num range
     */
    function revealWithRange(uint256 _startIndex, uint256 _amount) public {
        uint256 _end = _startIndex + _amount;
        require(_end <= _totalMinted() + _startTokenId(), "out of range");

        uint256[] memory _temp = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; ) {
            unchecked {
                _temp[i] = _startIndex++;
                i++;
            }
        }
        requestTokenReveal(_temp);
    }

    /**
     * @dev Allows the owner of the token to send a request to chainlink to reveal the real token id.
     * After sending the request, it will not be revealed immediately,
     * but will wait for chainlink to complete the verification and call back.
     * And you cannot send the request repeatedly.
     * @param _tokenIds List of token ids to be revealed.
     */
    function requestTokenReveal(uint256[] memory _tokenIds) public nonReentrant {
        require(_tokenIds.length > 0, "Requires at least one tokenid");

        uint256 requestId = VRF_COORDINATOR.requestRandomWords(
            chainlinkConfig.keyHash,
            chainlinkConfig.subscriptionId,
            chainlinkConfig.requestConfirms,
            chainlinkConfig.callbackGasLimit,
            uint32(_tokenIds.length)
        );

        for (uint256 i = 0; i < _tokenIds.length; ) {
            require(ownerOf(_tokenIds[i]) == msg.sender, "Not token owner");
            require(!_tokenRevealData[_tokenIds[i]].requested, "Already requested");

            _tokenRevealData[_tokenIds[i]].requested = true;
            _tokenRevealData[_tokenIds[i]].requestSeq = uint168(i);
            _tokenRevealRequest[requestId].push(uint16(_tokenIds[i]));

            emit RevealRequested(_tokenIds[i], requestId);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Calculate the supply of public minting based on the results of whitelist minting,
     * and start public minting.
     *
     * - This method requires the following conditions to be called:
     *     1. Contract owner
     *     2. Whitelist minting has ended (time reached or supply cap reached)
     */
    function startPubMinting() external onlyOwner {
        require(
            numberWhitelistMinted == WHITELIST_MINTING_SUPPLY || block.timestamp > WHITELIST_MINTING_END,
            "Whitelist minting is not over"
        );
        require(PUB_MINT_SUPPLY == 0, "Pub minting is already started");
        unchecked {
            PUB_MINT_SUPPLY = WHITELIST_MINTING_SUPPLY - numberWhitelistMinted + PUB_MINT_RESERVE;
        }
    }

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) public view returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _currentIndex) {
            return ownership;
        }
        ownership = _ownerships[tokenId];
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory) {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _currentIndex;
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, _currentIndex)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }
}
