// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../opensea/ERC721Tradable.sol";

contract NFT is ERC721Tradable {

    struct Level {
        uint8 stackLevel;
        uint8 nftLevel;
    }

    event OINFTMintEvent(
        address addr,
        uint256 id,
        uint8 stackLevel,
        uint8 nftLevel
    );

    mapping(uint256=>Level) public _levels;

    mapping(uint8=>uint32) public _nftTotalSupply;

    string private _baseUrl;

    constructor()
        ERC721Tradable("OINFT", "OINFT", address(0))
    {
        _baseUrl = "https://nft.oi.xyz/";
    }

    function baseTokenURI() override public view returns (string memory) {
        return _baseUrl;
    }

    function setBaseUrl(string calldata baseUrl_) public onlyOwner {
        _baseUrl = baseUrl_;
    }

    function setProxyRegistryAddress(address proxyRegistryAddress_) public onlyOwner {
        _setProxyRegistryAddress(proxyRegistryAddress_);
    }

    function mintTo(address to_,uint8 stackLevel_,uint8 nftLevel_) public onlyOwner {
        uint256 id = _mintTo(to_);
        _levels[id] = Level({
            stackLevel: stackLevel_,
            nftLevel: nftLevel_
        });
        ++_nftTotalSupply[stackLevel_];
        emit OINFTMintEvent(to_, id, stackLevel_, nftLevel_);
    }

}
