// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//1000000000000000
//
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/3d7a93876a2e5e1d7fe29b5a0e96e222afdc4cfa/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

contract Market1155 is ERC1155, Ownable , ReentrancyGuard { 
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _itemId;

    uint16 total = 10000;
    uint listingPrice;
    uint royalityPrice;
    uint floorPrice = 0.001 ether;

    enum Royality{FristBuy , SecondBuy , Active}
    mapping(uint256 => Royality) public status;
    mapping(uint256 => uint8) buyCounter;
    mapping(uint256 => uint16) minted;
    mapping(uint256 =>uint256) public parent;
    

    struct nftMinted {
        uint256 tokenId;
        uint16 amount;
        uint8 royalityPercent;
        address payable creator;
    }
    mapping(uint256 => nftMinted) nfts;

    mapping(uint256 => MarketItem) private idToMarketItem;
    mapping(address => mapping(uint256 => uint16)) amountNft;

    struct MarketItem {
        uint256 itemId;
        uint256 tokenId;
        uint16 amount;
        uint8 royalityPercent;
        address payable creator;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event MarketItemCreated(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        uint16 amount,
        uint8 royalityPercent,
        address creator,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );
    
    constructor() ERC1155(""){}

    function mint(address _creator, string memory _uri , uint16 _amount , uint8 _royalityPercent)public nonReentrant returns(uint256) {
        
        require(_royalityPercent<=100 , "should be between 0 and 10 percent");
        _setURI(_uri);
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
           

        
        
        require (minted[newTokenId] + _amount <= total, "All the NFT have been minted");
        _mint(_creator, newTokenId, _amount, "");
        // "" is data which is set empty
        minted[newTokenId] = _amount;
        
        nfts[newTokenId] = nftMinted(
            newTokenId,
            _amount,
            _royalityPercent,
            payable(_creator)
        );
        return(newTokenId);
    }

    function createMarketItem(address _creator, uint256 tokenId, uint16 _amount, uint256 price)payable public  returns(uint256) {
        require(_creator == nfts[tokenId].creator , "You are not creator!");
        require(price > floorPrice, "Price must be at least 0.001 ether");
        // require(msg.value == listingPrice,"Price must be equal to listing price");
        require(_amount <= minted[tokenId] , "there are not amount nft");
        _itemId.increment();
        uint256 newItem = _itemId.current();
        
        idToMarketItem[newItem] = MarketItem(
            newItem,
            tokenId,
            _amount,
            nfts[tokenId].royalityPercent,
            payable(_creator),
            payable(_creator),
            payable(address(this)),
            price,
            false
        );

        
        onERC1155Received(_creator, address(this), tokenId , _amount, "");
        _safeTransferFrom(_creator, address(this), tokenId , _amount, "");
        // nfts[tokenId] = nftMinted(
        //     tokenId,
        //     _amount,
        //     royalityPercent,
        //     payable(_creator)
        // ); 
        emit MarketItemCreated(
            newItem,
            tokenId,
            _amount,
            nfts[tokenId].royalityPercent,
            _creator,
            _creator,
            address(this),
            price,
            false
        );

        return(newItem);
    }

    function resellToken(uint256 itemId, uint16 _amount, uint256 price) public payable nonReentrant {
        require(idToMarketItem[itemId].owner == msg.sender,"Only item owner can perform this operation");
        // require(msg.value == listingPrice,"Price must be equal to listing price");
        if(idToMarketItem[itemId].amount == _amount){
        idToMarketItem[itemId].sold = false;
        idToMarketItem[itemId].price = price;
        idToMarketItem[itemId].seller = payable(msg.sender);
        idToMarketItem[itemId].owner = payable(address(this));
        _itemsSold.decrement();
        

        onERC1155Received(msg.sender, address(this), idToMarketItem[itemId].tokenId , _amount, "");
        _safeTransferFrom(msg.sender, address(this), idToMarketItem[itemId].tokenId , _amount , "");
        }
        else
        {
            // createMarketItem(idToMarketItem[itemId].creator, idToMarketItem[itemId].tokenId , _amount , price);
            _itemId.increment();
            uint256 newItem = _itemId.current();
        
            idToMarketItem[newItem] = MarketItem(
            newItem,
            idToMarketItem[itemId].tokenId,
            _amount,
            idToMarketItem[itemId].royalityPercent,
            payable(idToMarketItem[itemId].creator),
            payable(msg.sender),
            payable(address(this)),
            price,
            false
            );

            parent[newItem] = itemId;
            console.log(newItem);
            idToMarketItem[itemId].amount -= _amount;

            onERC1155Received(msg.sender, address(this), idToMarketItem[newItem].tokenId , _amount, "");
            _safeTransferFrom(msg.sender, address(this), idToMarketItem[newItem].tokenId , _amount , "");
        }
    }




    function buyMarketItem(uint256 itemId) public payable nonReentrant{
        uint256 price = idToMarketItem[itemId].price;
        uint256 royality = nfts[idToMarketItem[itemId].tokenId].royalityPercent;
        address creator = idToMarketItem[itemId].creator;
        address seller = idToMarketItem[itemId].seller;
        listingPrice = (price.mul(25)).div(1000);

        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        
        idToMarketItem[itemId].seller = payable(address(0));
        _itemsSold.increment();
        // if(buyCounter[itemId]<=3){buyCounter[itemId]+=1;}
        checkParent(itemId);
        // setStatus(buyCounter[itemId] , itemId);

        // payable(owner()).transfer(listingPrice);

        if(status[itemId] == Royality.Active && royality<=100){
            require(msg.value == price,"Please submit the asking price and royality in order to complete the purchase1");
            royalityPrice = (price.mul(royality)).div(1000);
            console.log(royalityPrice);
            payable(creator).transfer(royalityPrice);
            payable(seller).transfer(msg.value-(royalityPrice+listingPrice));
        }else{
            require(msg.value == price,"Please submit the asking price in order to complete the purchase2");
            payable(owner()).transfer(listingPrice);
            payable(seller).transfer(msg.value-listingPrice);
            console.log(listingPrice);
        }
        onERC1155Received(address(this), msg.sender, idToMarketItem[itemId].tokenId, idToMarketItem[itemId].amount , "");
        _safeTransferFrom(address(this), msg.sender, idToMarketItem[itemId].tokenId, idToMarketItem[itemId].amount , "");
    }


    function setStatus(uint256 _buyItem , uint256 itemId)private returns(Royality){
        if(_buyItem == 1 ){
            status[itemId] = Royality.FristBuy;
            
        }
        else if(_buyItem == 2){
            status[itemId] = Royality.SecondBuy;
            
        }
        else if(_buyItem > 2){
            status[itemId] = Royality.Active;
            
        }
        return(status[itemId]);
    }
    function checkParent(uint _idItem)public returns(Royality){
        uint check;
        check = _idItem;
        for(uint i = 0 ; i<=2 ; i++){
            check = parent[check];
            if(check == 0 && i == 0){
                status[_idItem] = Royality.FristBuy;
                break;
            }
            else if(i>=1){
                status[_idItem] = Royality.Active;
            }
        }
        return(status[_idItem]);
    }
    

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function totalNftMinted(uint256 _tokenId) public view returns(uint256){
        return minted[_tokenId];
    }
    //=========================================================================

    /* Returns all unsold market items */
    function fetchMarketItems() public view  returns (MarketItem[] memory) {
        uint256 itemCount = _itemId.current();
        uint256 unsoldItemCount = _itemId.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items that a user has purchased */
    function fetchMyPurchasedNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemId.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // /* Returns only items a user has listed */
    // function fetchMyItemsListed() public view returns (MarketItem[] memory) {
    //     uint256 totalItemCount = _itemId.current();
    //     uint256 itemCount = 0;
    //     uint256 currentIndex = 0;

    //     for (uint256 i = 0; i < totalItemCount; i++) {
    //         if (idToMarketItem[i + 1].seller == msg.sender) {
    //             itemCount += 1;
    //         }
    //     }

    //     MarketItem[] memory items = new MarketItem[](itemCount);
    //     for (uint256 i = 0; i < totalItemCount; i++) {
    //         if (idToMarketItem[i + 1].seller == msg.sender) {
    //             uint256 currentId = i + 1;
    //             MarketItem storage currentItem = idToMarketItem[currentId];
    //             items[currentIndex] = currentItem;
    //             currentIndex += 1;
    //         }
    //     }
    //     return items;
    // }

    // function fetchMyMintNFTs() public view returns(nftMinted [] memory){
    //    uint256 totalItemCount = _tokenIds.current();
    //     uint256 tokenCount = 0;
    //     uint256 currentIndex = 0;

    //     for (uint256 i = 0; i < totalItemCount; i++) {
    //         if (nfts[i + 1].creator == msg.sender) {
    //             tokenCount += 1;
    //         }
    //     }

    //     nftMinted[] memory items = new nftMinted[](tokenCount);
    //     for (uint256 i = 0; i < totalItemCount; i++) {
    //         if (nfts[i + 1].creator == msg.sender) {
    //             uint256 currentId = i + 1;
    //             nftMinted storage currentItem = nfts[currentId];
    //             items[currentIndex] = currentItem;
    //             currentIndex += 1;
    //         }
    //     }
    //     return items;
    // }
//===================================================================================
}


