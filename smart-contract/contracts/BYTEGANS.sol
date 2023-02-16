// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "./Base64.sol";

contract BYTEGANS is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  

  address public ownerAddress;
  address public adminAddress;
  string public collectionDescription = "bitGANs on-chained";
  string public collectionName = "chainGANs by Pindar Van Arman";
  string public defaultMeta = "data:application/json;base64,ewogICAgIm5hbWUiOiJtZXNzZW5nZXIgZ2hvc3RHQU4iLAogICAgImNvbGxlY3Rpb25fbmFtZSI6ImJ5dGVHQU5zIGJ5IFZhbiBBcm1hbiIsIAogICAgImRlc2NyaXB0aW9uIjoiYml0R0FOcyBvbi1jaGFpbmVkIiwgCiAgICAiYXR0cmlidXRlcyI6WwogICAgeyJ0cmFpdF90eXBlIjoic3RhdHVzIiwidmFsdWUiOiJwcm9jZXNzaW5nIn0gICAgCiAgICBdLAogICAgImltYWdlIjoiZGF0YTppbWFnZS9zdmcreG1sO3V0ZjgsPHN2ZyB3aWR0aD0nMTExMScgaGVpZ2h0PScxMTExJyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHhtbG5zOnhsaW5rPSdodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rJz4gPGltYWdlIGltYWdlLXJlbmRlcmluZz0ncGl4ZWxhdGVkJyB3aWR0aD0nMTExMScgaGVpZ2h0PScxMTExJyB4bGluazpocmVmPSdkYXRhOmltYWdlL2dpZjtiYXNlNjQsUjBsR09EbGhDd0FMQVBFQUFNQUFBRENQajJCZlh3Qy92eUgvQzA1RlZGTkRRVkJGTWk0d0F3RUFBQUFoK1FRRUZBQUFBQ3dBQUFBQUN3QUxBQUFDSUp5UENDczVDNXQ2VHdRRmdWUkNqM3NFb3VpSWdnUWF3V2w5aWJraEoza1VBQ0g1QkFVVUFBQUFMQUVBQVFBSUFBb0FnZ0FBQU1BQUFEQ1BqMkJmWHdDL3Z3QUFBQUFBQUFBQUFBTWFDS3EwRHUzQjZDZ0U0cElOTThNWkVTalpBQVhsNHdFbWtBQUFJZmtFQlJRQUFBQXNBZ0FCQUFjQUNnQ0NBQUFBd0FBQU1JK1BZRjlmQUwrL0FBQUFBQUFBQUFBQUF4b0lzOURUQ2dZd0lRRVhpTWsxL2MwbFlFMHdudFF3ZWlJRUpBQWgrUVFGRkFBQUFDd0RBQU1BQmdBSUFJSUFBQURBQUFBd2o0OWdYMThBdjc4QUFBQUFBQUFBQUFBREVRaXFza29Pd0RXbkNtTXd2SVRJZ0pjQUFDSDVCQVVVQUFBQUxBSUFBUUFIQUFvQWdnQUFBTUFBQURDUGoyQmZYd0MvdndBQUFBQUFBQUFBQUFNYUNMVFFOQzAwMkVCNE53TWF4UTVENERWalpUbEVWS1ZEU1NRQUlma0VCUlFBQUFBc0FnQUNBQWNBQ1FDQ0FBQUF3QUFBTUkrUFlGOWZBTCsvQUFBQUFBQUFBQUFBQXhVSUJNemJUTUE0bDVSTkVJSmJtTUMzREFDcEFRa0FJZmtFRFJRQUFBQXNBUUFDQUFnQUNRQ0NBQUFBd0FBQU1JK1BZRjlmQUwrL0FBQUFBQUFBQUFBQUF4a0lJS0toQzRJSFJpQ1hEaG5ZRUIwRkNadmttS2ZTUkVvQ0FDSDVCQVVVQUFBQUxBSUFBZ0FIQUFrQWdRQUFBTUFBQURDUGp3Qy92d0lYQkdSaGFLQVNSbnpOR1FuUk9MVUZWWDNBSUpRYlVBQUFJZmtFQlJRQUFBQXNBUUFDQUFnQUNRQ0JBQUFBd0FBQU1JK1BBTCsvQWhoRVBta0hJQ1BDa0JKTTVxQXh3cmJXZmVJWGpFMHBoZ1VBSWZrRUJSUUFBQUFzQVFBQkFBa0FDUUNDQUFBQXdBQUFNSStQWUY5ZkFMKy9BQUFBQUFBQUFBQUFBeG9JQ3RGTGhMVUE0S2lVRWpHeXN4R2pDRkUwQ0V1cXJpSWJKQUFoK1FRRkZBQUFBQ3dCQUFFQUNBQUtBSUlBQUFEQUFBQXdqNDlnWDE4QXY3OEFBQUFBQUFBQUFBQURHd2dhT2dyc2tVVkNGZXNCdklPd3dEUnQ0U1k0bzZhdUNwWUNDUUE3JyAvPiA8L3N2Zz4iICAKfQ==";

  struct tokenData {
        string name;
        string GIF;
        string trait;
        bool updated;
  }

  mapping (uint256 => tokenData) public tokens;
  
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx
    
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    
  }

  modifier requireAdminOrOwner() {
  require(adminAddress == msg.sender || ownerAddress == msg.sender,"Requires admin or owner privileges");
  _;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function setAdminAddress(address _adminAddress) public onlyOwner{
        adminAddress = _adminAddress;
  }

  //Set permissions for relayer
    function setTokenInfo(uint _tokenId, string memory _name, string memory _GIF, string memory _trait) public requireAdminOrOwner() { 
        //require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        tokens[_tokenId].name = _name;
        tokens[_tokenId].trait = _trait;
        tokens[_tokenId].GIF = _GIF;
        tokens[_tokenId].updated = true;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function buildImage(uint256 _tokenId) public view returns(string memory) {      
      return Base64.encode(bytes(
          abi.encodePacked(
              '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 128 128" style= "image-rendering:pixelated; image-rendering:-moz-crisp-edges; -ms-interpolation-mode:nearest-neighbor; background-repeat:no-repeat; background-size:100%; background-image:url(data:image/gif;base64,',tokens[_tokenId].GIF,'"/>'                            
          )
      ));
  }

  function buildMetadata(uint256 _tokenId) public view returns(string memory) {

        if(tokens[_tokenId].updated != true){
            return defaultMeta;
        }
        else{
           return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"', 
                          tokens[_tokenId].name,
                          '", "description":"', 
                          collectionDescription,
                          '", "attributes":', 
                          tokens[_tokenId].trait,
                          ', "image": "', 
                          'data:image/svg+xml;base64,', 
                          buildImage(_tokenId),
                          '"}'))))); 
        }     
      
  }

  function getTokenInfo(uint _tokenId) public view returns (string memory, string memory, string memory) {
        return (tokens[_tokenId].name,tokens[_tokenId].GIF, tokens[_tokenId].trait);
  }   

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
      return buildMetadata(_tokenId);
  }  

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {    
    // Sets percentage to be sent to collaborator
    // =============================================================================
    (bool hs, ) = payable(0xbf1aB3DDB7b1F2d8f302C1048a33e3b382887B63).call{value: address(this).balance * 5 / 100}('');
    require(hs);
    // =============================================================================

    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }  
}
