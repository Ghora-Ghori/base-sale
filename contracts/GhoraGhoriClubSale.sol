// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

interface IERC1155 {
  function mintBatch(address _to, uint256[] calldata _ids, uint256[] calldata _amounts, string[] calldata _uris, bytes calldata _data) external;
  function balanceOf(address _owner, uint256 _id) external view returns(uint256);
  function setURI(uint256 _id, string calldata _newURI) external;
}

interface IERC1155Burnable {
  function burn(uint256 _tokenId, uint256 _amount) external;
  function balanceOf(address _owner, uint256 _id) external view returns(uint256);
}

/**
 *
 *      ╔═╗╦ ╦╔═╗╦═╗╔═╗  ╔═╗╦ ╦╔═╗╦═╗╦  ╔═╗╦  ╦ ╦╔╗
 *      ║ ╦╠═╣║ ║╠╦╝╠═╣  ║ ╦╠═╣║ ║╠╦╝║  ║  ║  ║ ║╠╩╗
 *      ╚═╝╩ ╩╚═╝╩╚═╩ ╩  ╚═╝╩ ╩╚═╝╩╚═╩  ╚═╝╩═╝╚═╝╚═╝
 *
 *  GHora Ghori Club - Created by SXTW//MΞTΛ & Ryuzaki01
 *
 */
contract GhoraGhoriClubSale is Ownable, ReentrancyGuard {
  IERC1155 public nft;

  bool     public enableSale = false;
  uint256  public price = 0.003 ether;
  uint256  public limitPerOrder;
  uint256  public maxSupply = 5010;
  uint256  private currentSupply = 0;

  address private tokenAddress;
  mapping(address => uint8) private burnerList;

  event Buy(address buyer, uint256 amount, uint256[] tokenIds);

  struct Burner {
    address tokenAddress;
    uint8 requiredAmount;
  }

  constructor(
    address _tokenAddress,
    uint256 _maxSupply,
    uint256 _currentSupply,
    uint256 _limitPerOrder, // 10
    bool _enable
  ) Ownable() ReentrancyGuard() {
    nft = IERC1155(_tokenAddress);
    tokenAddress = _tokenAddress;
    maxSupply = _maxSupply;
    currentSupply = _currentSupply;
    limitPerOrder = _limitPerOrder;
    enableSale = _enable;
  }

  function setTokenAddress(address _tokenAddress, uint256 _maxSupply, uint256 _currentSupply) public onlyOwner {
    nft = IERC1155(_tokenAddress);
    tokenAddress = _tokenAddress;
    maxSupply = _maxSupply;
    currentSupply = _currentSupply;
  }

  function toggleSale() public onlyOwner {
    enableSale = !enableSale;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setCurrentSupply(uint256 _currentSupply) public onlyOwner {
    currentSupply = _currentSupply;
  }

  function currentTokenIndex() public view returns (uint256) {
    return currentSupply + 1;
  }

  function setBurnerList(Burner[] calldata _burnerlist) public onlyOwner {
    for (uint256 i = 0; i < _burnerlist.length; ++i) {
      burnerList[_burnerlist[i].tokenAddress] = _burnerlist[i].requiredAmount;
    }
  }

  function mergeNFT(uint256 _tokenId, address _burnerAddress, uint256 _burnerTokenId, string memory _newURI) external nonReentrant senderIsUser {
    uint8 requiredAmount = burnerList[_burnerAddress];
    require(requiredAmount > 0, "You are not allowed to merge this");

    IERC1155Burnable burner = IERC1155Burnable(_burnerAddress);

    require(bytes(_newURI).length > 0, "You have to set the new URI");
    require(burner.balanceOf(msg.sender, _burnerTokenId) >= requiredAmount, "You don't have enough NFT to merge");
    require(nft.balanceOf(msg.sender, _tokenId) == 1, "You are not the owner");

    burner.burn(_burnerTokenId, requiredAmount);
    nft.setURI(_tokenId, _newURI);
  }

  function saleMint(uint256 _amount, string[] memory _uris) external payable nonReentrant senderIsUser {
    uint256 currentIdx = currentTokenIndex();
    uint256 newTotalSupply = currentSupply + _amount;
    require(enableSale, "Sale is not active");
    require(newTotalSupply <= maxSupply, "Purchase would exceed max tokens");
    require(_amount <= limitPerOrder, "Purchase would exceed limit per order");
    require(msg.value >= _amount * price, "Ether value sent is not correct");

    uint256[] memory _ids = new uint256[](_amount);
    uint256[] memory _amounts;
    for (uint256 i; i < _amount; ++i) {
      _ids[i] = currentIdx + i;
      _amounts[i] = 1;
    }

    nft.mintBatch(msg.sender, _ids, _amounts, _uris, new bytes(0x0));
    currentSupply = newTotalSupply;
    emit Buy(msg.sender, _amount, _ids);
  }

  function withdrawETH() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function supply(uint256 _tokenId) public view returns(uint256) {
    return nft.balanceOf(address(this), _tokenId);
  }

  modifier senderIsUser() {
    require(tx.origin == msg.sender, "Sender is a contract");
    _;
  }
}