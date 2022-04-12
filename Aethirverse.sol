//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleCollectible is ERC721, Ownable {
    uint256 public tokenCounter;
    address public wl_nft;
    address public yieldToken;
    uint16 public WL_NFT_TOKEN_ID = 2;

    uint256 private _presalePrice = .077 ether; 
    uint256 private _salePrice = .077 ether;

    uint256 private _maxPerTx = 21; // Set to one higher than actual, to save gas on <= checks.

    uint256 private _presaleSupply = 3333;
    uint256 private _totalSupply = 7777; 

    string private _baseTokenURI;
    string private _baseSuffix;
    uint private _saleState; // 0 - No sale. 1 - Presale. 2 - Main Sale.

    constructor () ERC721 ("Raggedy Army","RAGGEDY")  {
        setBaseURI('ipfs://QmcZjhgnfrgxN5iqUtkYziU1HXw8XX9rCMA28Bwh3xG2tz');
        setBaseSuffix('.json');
    }

    function mintPresaleCollectibles(uint256 _count, bool isUsingWLNFT) public payable {
        require(isPresaleOpen(), "Presale is not yet open. See wenPresale and wenSale for more info");
        require(!isPresaleComplete(), "Presale is over. See wenSale for more info");
        require((_count + tokenCounter) <= getPresaleSupply(), "Ran out of NFTs for presale! Sry!");
        require(msg.value >= (_presalePrice * _count), "Ether value sent is too low");
        if (isUsingWLNFT) {
            IERC1155(wl_nft).safeTransferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, 2, _count, '');
        }
        createCollectibles(msg.sender, _count);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");


        return string(abi.encodePacked(getBaseURI(), Strings.toString(tokenId), getBaseSuffix()));
    }
    function mintCollectibles(uint256 _count) external payable {
        require(isSaleOpen(), "Sale is not yet open");
        require(isPresaleComplete(), "Presale has not started or is ongoing");
        require(_count < _maxPerTx, "Cant mint more than mintMax");
        require((_count + tokenCounter) <= (_totalSupply - 300), "Ran out of NFTs for sale! Sry!");
        require(msg.value >= (_salePrice * _count), "Ether value sent is not correct");

        createCollectibles(msg.sender, _count);
    }

    function ownerMint(uint256 count, address[] memory users) external onlyOwner {
        require((_count * users.length) + tokenCounter < _totalSupply, "Cant mint more than mintMax");

        for(int i = 0; i < users.length; i++) {
            createCollectibles(users[i], count);
        }
    }

    function createCollectibles(address _user, uint256 _count) private {
        for(uint i = 0; i < _count; i++) {
            createCollectible(_user);
        }
    }

    function createCollectible(address _user) private {
            _safeMint(_user, tokenCounter);
            tokenCounter = tokenCounter + 1;
    }
    
    function maxMintsPerTransaction() public view returns (uint) {
        return _maxPerTx - 1; //_maxPerTx is off by 1 for require checks in HOF Mint. Allows use of < instead of <=, less gas
    }

    function wenPresale() external view returns (string memory) {
        if(!isPresaleOpen()) return "#soon";
        return isPresaleComplete() ? "complete" : "now!";
    }

    function wenSale() external view returns (string memory) {
        if(!isSaleOpen()) return "#soon";
        return isSaleComplete() ? "complete" : "now!";
    }

    function isSaleOpen() public view returns (bool) {
        return _saleState == 2;
    }

    function isSaleComplete() public view returns (bool) {
        return tokenCounter == _totalSupply;
    }
    function isPresaleOpen() public view returns (bool) {
        return _saleState >= 1;
    }
    function isPresaleComplete() public view returns (bool) {
        return tokenCounter >= _presaleSupply;
    }
    
    function getSaleState() private view returns (uint){
        return _saleState;
    }
    
    function setSaleState(uint saleState) external onlyOwner {
        _saleState = saleState;
    }
    function setPresalePrice(uint256 price) external onlyOwner {
        _presalePrice = price;
    }
    
    function setSalePrice(uint256 price) external onlyOwner {
        _salePrice = price;
    }
    function setPresaleSupply(uint256 supply) external onlyOwner {
        _presaleSupply = supply;
    }
    
    function getSalePrice() private view returns (uint) {
        return _salePrice;
    }
    
    function getPresalePrice() private view returns (uint) {
        return _presalePrice;
    }
    function getPresaleSupply() private view returns (uint) {
        return _presaleSupply;
    }

    function getTotalSupply() private view returns (uint) {
        return _totalSupply;
    }

    function setWLNFT(address _nft) public onlyOwner {
        wl_nft = _nft;
    }


    function setYieldToken(address _nft) public onlyOwner {
        yieldToken = _nft;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    function setBaseSuffix(string memory suffix) public onlyOwner {
        _baseSuffix = suffix;
    }

    function getBaseURI() public view returns (string memory){
        return _baseTokenURI;
    }

    function getBaseSuffix() public view returns (string memory){
        return _baseSuffix;
    }
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }



	function getReward() external {
		yieldToken.updateReward(msg.sender, address(0), 0);
		yieldToken.getReward(msg.sender);
	}

	function transferFrom(address from, address to, uint256 tokenId) public override {
        if (yieldToken != address(0)) {
		    yieldToken.updateReward(from, to, tokenId);
        }
        ERC721.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        if (yieldToken != address(0)) {
		    yieldToken.updateReward(from, to, tokenId);
        }
		ERC721.safeTransferFrom(from, to, tokenId, _data);
	}
	function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        if (yieldToken != address(0)) {
		    yieldToken.updateReward(from, to, tokenId);
        }
		ERC721.safeTransferFrom(from, to, tokenId);
	}
}
