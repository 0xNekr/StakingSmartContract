// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./NFTContractIsERC721A.sol";
import "./TokenContractIsERC20.sol";

contract NFTStaking {

    uint public totalStaked; 

    struct Staking {
        uint24 tokenId; 
        uint48 stakingStartTime;
        address owner;
    }

    mapping (uint => Staking) NFTsStaked;

    uint rewardsPerHour = 10000;

    TokenContractIsERC20 token;
    NFTContractIsERC721A nft;

    event Staked(address indexed owner, uint tokenId, uint value);
    event UnStaked(address indexed owner, uint tokenId, uint value);
    event Claimed(address indexed owner, uint amount);
    
    constructor(TokenContractIsERC20 _token, NFTContractIsERC721A _nft) {
        token = _token;
        nft = _nft;
    }

    function stake(uint[] calldata tokenIds) external {
        uint tokenId; 

        totalStaked += tokenIds.length;

        for (uint i = 0 ; i < tokenIds.length ; i++) {
            tokenId = tokenIds[i];
            require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
            require(NFTsStaked[tokenId].stakingStartTime == 0, "Already staked");

            nft.transferFrom(msg.sender, address(this), tokenId);
            emit Staked(msg.sender, tokenId, block.timestamp);
            
            NFTsStaked[tokenId] = Staking({
                tokenId: uint24(tokenId),
                stakingStartTime: uint48(block.timestamp),
                owner: msg.sender
            });
        }
    }

    function _unstakeMany(address _owner, uint[] calldata _tokenIds) internal {
        uint tokenId;

        totalStaked -= _tokenIds.length;

        for (uint i = 0 ; i < _tokenIds.length ; i++) {
            tokenId = _tokenIds[i];
            require(NFTsStaked[tokenId].owner == msg.sender, "Not the owner");

            emit UnStaked(msg.sender, tokenId, block.timestamp);
            delete NFTsStaked[tokenId];

            nft.transferFrom(address(this), _owner, tokenId);
        }
    }

    function claim(uint[] calldata tokenIds) external {
        _claim(msg.sender, tokenIds, false);
    }

    function unstake(uint[] calldata tokenIds) external {
        _claim(msg.sender, tokenIds, true);
    }

    function _claim(address _owner, uint[] calldata _tokenIds, bool _unstake) internal {
        uint tokenId;
        uint earned; 
        uint totalEarned; 

        for (uint i = 0 ; i < _tokenIds.length ; i++) {
            tokenId = _tokenIds[i];
            Staking memory thisStake = NFTsStaked[tokenId];
            require(thisStake.owner == _owner, "Not the owner, you cannot claim the awards");

            uint stakingStartTime = thisStake.stakingStartTime;

            earned = (block.timestamp - stakingStartTime) * rewardsPerHour / 3600;
            totalEarned += earned; 

            NFTsStaked[tokenId] = Staking({
                tokenId: uint24(tokenId),
                stakingStartTime: uint48(block.timestamp),
                owner: _owner
            });
        }

        if (totalEarned > 0) {
            token.mint(_owner, totalEarned);
        }

        if (_unstake) {
            _unstakeMany(_owner, _tokenIds);
        }

        emit Claimed(_owner, totalEarned);
    }

    function getRewardAmount(address owner, uint[] calldata tokenIds) external view returns(uint) {
        uint tokenId;
        uint earned; 
        uint totalEarned; 

        for (uint i = 0 ; i < tokenIds.length ; i++) {
            tokenId = tokenIds[i];
            Staking memory thisStake = NFTsStaked[tokenId];
            require(thisStake.owner == owner, "Not the owner, you cannot claim the awards");
            
            uint stakingStartTime = thisStake.stakingStartTime;

            earned = (block.timestamp - stakingStartTime) * rewardsPerHour / 3600;
            totalEarned += earned; 
        }

        return totalEarned;
    }

    function tokenStakedByOwner(address owner) external view returns(uint[] memory) {
        uint totalSupply = nft.totalSupply();
        uint[] memory tmp = new uint[](totalSupply);
        uint index = 0;

        for(uint i = 0 ; i < totalSupply ; i++) {
            if (NFTsStaked[i].owner == owner) {
                tmp[index] = i; 
                index++;
            }
        }

        uint[] memory tokens = new uint[](index);

        for(uint i = 0 ; i < index ; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }
}