// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 *
 *      ╔═╗╦ ╦╔═╗╦═╗╔═╗  ╔═╗╦ ╦╔═╗╦═╗╦  ╔═╗╦  ╦ ╦╔╗
 *      ║ ╦╠═╣║ ║╠╦╝╠═╣  ║ ╦╠═╣║ ║╠╦╝║  ║  ║  ║ ║╠╩╗
 *      ╚═╝╩ ╩╚═╝╩╚═╩ ╩  ╚═╝╩ ╩╚═╝╩╚═╩  ╚═╝╩═╝╚═╝╚═╝
 *
 *  GHora Ghori Club - Created by SXTW//MΞTΛ & Ryuzaki01
 *
 */
contract GhoraGhoriClub is ERC1155, Ownable, Pausable, ERC1155Supply {
  string private unrevealedUri = "ipfs://bafkreifqsokhhinprhwpchwmumuzbhe6hrmmhrsjwriq3gpos66jbknzry";
  address private saleContract;
  bool private reveal = false;

  string public name;
  string public symbol;

  mapping(uint256 => string) private uris;

  constructor() ERC1155("") {
    name = "Ghora Ghori Club";
    symbol = "GGC";
    saleContract = msg.sender;
  }

  function setReveal(bool _reveal) public onlyOwner {
    reveal = _reveal;
  }

  function setSaleContract(address _saleContract) public onlyOwner {
    saleContract = _saleContract;
  }

  function setURI(uint256 _tokenId, string memory _newURI) public virtual {
    uris[_tokenId] = _newURI;
  }

  function uri (uint256 _tokenId) override public view returns (string memory) {
    if (!reveal) {
      return string(
        abi.encodePacked(
          unrevealedUri
        )
      );
    }

    return string(
      abi.encodePacked(
        uris[_tokenId]
      )
    );
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mintBatch(address to, uint256[] memory _ids, uint256[] memory _amounts, string[] memory _uris, bytes memory _data)
  public
  onlyController
  virtual
  {
    for (uint256 i; i < _ids.length; ++i) {
      uris[_ids[i]] = _uris[i];
    }
    _mintBatch(to, _ids, _amounts, _data);
  }

  function withdrawAllETH() public pure returns (string memory) {
    return "Sorry, it was just a prank :D";
  }

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
  internal
  whenNotPaused
  override(ERC1155, ERC1155Supply)
  {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function isApprovedForAll(
    address _owner,
    address _operator
  ) public override view returns (bool isOperator) {
    // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
    if (_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
      return true;
    }

    // if Sale's ERC1155 Proxy Address is detected, auto-return true
    if (_operator == saleContract) {
      return true;
    }

    // otherwise, use the default ERC1155.isApprovedForAll()
    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  modifier onlyController {
    require(msg.sender == saleContract, "Oopss");
    _;
  }
}