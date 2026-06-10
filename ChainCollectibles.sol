 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.20;
 
 import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
 import "@openzeppelin/contracts/access/Ownable.sol";
 import "@openzeppelin/contracts/utils/Strings.sol";
 import "@openzeppelin/contracts/utils/Base64.sol";
 
 contract ChainCollectibles is ERC721, Ownable {
     using Strings for uint256;
 
     uint256 public maxSupply;
     uint256 public mintPrice;
     uint256 public totalMinted;
     uint256 public maxPerWallet = 5;
     string public projectName;
     string public projectDescription;
     address public royaltyRecipient;
     uint256 public royaltyBps = 500; // 5%
 
     bytes32 private immutable seed;
     mapping(address => uint256) public mintCount;
 
     string[10] private paletteHex = [
         "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
         "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9"
     ];
 
     string[10] private paletteLight = [
         "#FFE0E0", "#D4F5F2", "#D4EDF7", "#E0F0E8", "#FFF8E0",
         "#F5E6F5", "#E0F5F0", "#FCF5DC", "#EBE0F0", "#E0F0FA"
     ];
 
     event Minted(address indexed minter, uint256 indexed tokenId, uint256 timestamp);
 
     constructor(
         string memory _projectName,
         string memory _projectDescription,
         uint256 _maxSupply,
         uint256 _mintPrice
     ) ERC721(string(abi.encodePacked(_projectName, " Genesis")), "CGEN") Ownable(msg.sender) {
         projectName = _projectName;
         projectDescription = _projectDescription;
         maxSupply = _maxSupply;
         mintPrice = _mintPrice;
         royaltyRecipient = msg.sender;
         seed = keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao));
     }
 
     function mint(uint256 quantity) external payable {
         require(totalMinted + quantity <= maxSupply, "Exceeds max supply");
         require(msg.value >= mintPrice * quantity, "Insufficient payment");
         require(mintCount[msg.sender] + quantity <= maxPerWallet, "Exceeds wallet max");
 
         for (uint256 i = 0; i < quantity; i++) {
             totalMinted++;
             mintCount[msg.sender]++;
             _safeMint(msg.sender, totalMinted);
             emit Minted(msg.sender, totalMinted, block.timestamp);
         }
     }
 
     function tokenURI(uint256 tokenId) public view override returns (string memory) {
         require(_ownerOf(tokenId) != address(0), "Token does not exist");
 
         string[13] memory parts;
         parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" width="400" height="400">';
         parts[1] = '<rect width="400" height="400" fill="';
         parts[2] = _getBgLight(tokenId);
         parts[3] = '"/>';
         parts[4] = _getShapeSVG(tokenId);
         parts[5] = _getDecorativeSVG(tokenId);
         parts[6] = _getRingSVG(tokenId);
         parts[7] = '<circle cx="200" cy="200" r="';
         parts[8] = _getValue(tokenId, 3, 8, 14).toString();
         parts[9] = '" fill="none" stroke="';
         parts[10] = _getAccent(tokenId);
         parts[11] = '" stroke-width="2" opacity="0.3"/>';
         parts[12] = '</svg>';
 
         string memory svg = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9], parts[10], parts[11], parts[12]));
 
         string memory imageURI = string(abi.encodePacked(
             "data:image/svg+xml;base64,",
             Base64.encode(bytes(svg))
         ));
 
         string memory attrs = string(abi.encodePacked(
             '{"trait_type":"Background","value":"', _getBgName(tokenId), '"},',
             '{"trait_type":"Shape","value":"', _getShapeName(tokenId), '"},',
             '{"trait_type":"Accent","value":"', _getAccentName(tokenId), '"},',
             '{"trait_type":"Ring Size","value":"', _getValue(tokenId, 3, 8, 14).toString(), '"}'
         ));
 
         string memory meta = string(abi.encodePacked(
             '{"name":"', projectName, ' #', tokenId.toString(), '",',
             '"description":"', projectDescription, '",',
             '"image":"', imageURI, '",',
             '"attributes":[', attrs, ']}'
         ));
 
         return string(abi.encodePacked(
             "data:application/json;base64,",
             Base64.encode(bytes(meta))
         ));
     }
 
     /* ---------- Generative SVG ---------- */
 
     function rand(uint256 tokenId, uint256 offset) private view returns (uint256) {
         return uint256(keccak256(abi.encodePacked(seed, tokenId, offset)));
     }
 
     function _getValue(uint256 tokenId, uint256 offset, uint256 min, uint256 max) private view returns (uint256) {
         return min + (rand(tokenId, offset) % (max - min + 1));
     }
 
     function _pick(uint256 tokenId, uint256 offset, uint256 length) private view returns (uint256) {
         return rand(tokenId, offset) % length;
     }
 
     function _getBgLight(uint256 tokenId) private view returns (string memory) {
         return paletteLight[_pick(tokenId, 0, 10)];
     }
 
     function _getBgName(uint256 tokenId) private view returns (string memory) {
         string[10] memory names = ["Coral","Teal","Sky","Sage","Sunny","Plum","Mint","Gold","Lavender","Cerulean"];
         return names[_pick(tokenId, 1, 10)];
     }
 
     function _getAccent(uint256 tokenId) private view returns (string memory) {
         return paletteHex[_pick(tokenId, 2, 10)];
     }
 
     function _getAccentName(uint256 tokenId) private view returns (string memory) {
         string[10] memory names = ["Rose","Teal","Blue","Sage","Yellow","Plum","Mint","Gold","Purple","Sky"];
         return names[_pick(tokenId, 3, 10)];
     }
 
     function _getShapeName(uint256 tokenId) private view returns (string memory) {
         string[6] memory shapes = ["Orbit","Hexagon","Diamond","Star","Bloom","Wave"];
         return shapes[_pick(tokenId, 4, 6)];
     }
 
     function _getShapeSVG(uint256 tokenId) private view returns (string memory) {
         string memory accent = _getAccent(tokenId);
         uint256 shapeIdx = _pick(tokenId, 4, 6);
         string[30] memory parts;
         string memory opacity = _getValue(tokenId, 5, 1, 5) % 2 == 0 ? "0.6" : "0.8";
 
         if (shapeIdx == 0) {
             // Orbit: concentric circles with dots
             uint256 r1 = _getValue(tokenId, 6, 40, 90);
             uint256 r2 = r1 + _getValue(tokenId, 7, 20, 50);
             parts[0] = '<circle cx="200" cy="200" r="'; parts[1] = r1.toString(); parts[2] = '" fill="'; parts[3] = accent; parts[4] = '" opacity="'; parts[5] = opacity; parts[6] = '"/>';
             parts[7] = '<circle cx="200" cy="200" r="'; parts[8] = r2.toString(); parts[9] = '" fill="none" stroke="'; parts[10] = accent; parts[11] = '" stroke-width="3" opacity="0.4"/>';
             return string(abi.encodePacked(parts[0],parts[1],parts[2],parts[3],parts[4],parts[5],parts[6],parts[7],parts[8],parts[9],parts[10],parts[11]));
         }
 
         if (shapeIdx == 1) {
             // Hexagon
             uint256 size = _getValue(tokenId, 6, 50, 100);
             uint256 h = size * 866 / 1000;
             uint256 cx = 200; uint256 cy = 200;
             parts[0] = '<polygon points="';
             for (uint256 i = 0; i < 6; i++) {
                 uint256 angle = i * 60;
                 int256 x = int256(cx) + int256(size) * int256(_cos(angle)) / 1000;
                 int256 y = int256(cy) + int256(size) * int256(_sin(angle)) / 1000;
                 if (i > 0) parts[0] = string(abi.encodePacked(parts[0], " "));
                 parts[0] = string(abi.encodePacked(parts[0], uint256(x).toString(), ",", uint256(y).toString()));
             }
             parts[0] = string(abi.encodePacked(parts[0], '" fill="', accent, '" opacity="', opacity, '"/>'));
             return parts[0];
         }
 
         if (shapeIdx == 2) {
             // Diamond
             uint256 d = _getValue(tokenId, 6, 50, 110);
             parts[0] = '<polygon points="200,'; parts[1] = (200 - d).toString(); parts[2] = ' '; parts[3] = (200 + d).toString(); parts[4] = ',200 200,'; parts[5] = (200 + d).toString(); parts[6] = ' '; parts[7] = (200 - d).toString(); parts[8] = ',200" fill="'; parts[9] = accent; parts[10] = '" opacity="'; parts[11] = opacity; parts[12] = '"/>';
             return string(abi.encodePacked(parts[0],parts[1],parts[2],parts[3],parts[4],parts[5],parts[6],parts[7],parts[8],parts[9],parts[10],parts[11],parts[12]));
         }
 
         if (shapeIdx == 3) {
             // Star - 8 pointed
             uint256 r1 = _getValue(tokenId, 6, 40, 70);
             uint256 r2 = r1 + _getValue(tokenId, 7, 15, 40);
             parts[0] = '<polygon points="';
             for (uint256 i = 0; i < 8; i++) {
                 uint256 r = (i % 2 == 0) ? r2 : r1;
                 int256 angle = int256(i) * 45;
                 int256 x = 200000 + int256(r) * _cos(uint256(angle)) / 1000;
                 int256 y = 200000 + int256(r) * _sin(uint256(angle)) / 1000;
                 if (i > 0) parts[0] = string(abi.encodePacked(parts[0], " "));
                 parts[0] = string(abi.encodePacked(parts[0], uint256(x / 1000).toString(), ",", uint256(y / 1000).toString()));
             }
             parts[0] = string(abi.encodePacked(parts[0], '" fill="', accent, '" opacity="', opacity, '"/>'));
             return parts[0];
         }
 
         if (shapeIdx == 4) {
             // Bloom: overlapping circles
             uint256 br = _getValue(tokenId, 6, 25, 45);
             parts[0] = '<circle cx="200" cy="180" r="'; parts[1] = br.toString(); parts[2] = '" fill="'; parts[3] = accent; parts[4] = '" opacity="'; parts[5] = opacity; parts[6] = '"/>';
             parts[7] = '<circle cx="180" cy="210" r="'; parts[8] = br.toString(); parts[9] = '" fill="'; parts[10] = accent; parts[11] = '" opacity="'; parts[12] = keccak256(bytes(opacity)) == keccak256(bytes("0.6")) ? "0.7" : "0.5"; parts[13] = '"/>';
             parts[14] = '<circle cx="220" cy="210" r="'; parts[15] = br.toString(); parts[16] = '" fill="'; parts[17] = accent; parts[18] = '" opacity="'; parts[19] = keccak256(bytes(opacity)) == keccak256(bytes("0.6")) ? "0.5" : "0.7"; parts[20] = '"/>';
             return string(abi.encodePacked(parts[0],parts[1],parts[2],parts[3],parts[4],parts[5],parts[6],parts[7],parts[8],parts[9],parts[10],parts[11],parts[12],parts[13],parts[14],parts[15],parts[16],parts[17],parts[18],parts[19],parts[20]));
         }
 
         // Wave: flowing curves
         uint256 wy = _getValue(tokenId, 6, 120, 180);
         parts[0] = '<path d="M60,'; parts[1] = wy.toString(); parts[2] = ' Q130,'; parts[3] = (wy - 50).toString(); parts[4] = ' 200,'; parts[5] = wy.toString(); parts[6] = ' T340,'; parts[7] = wy.toString(); parts[8] = '" fill="none" stroke="'; parts[9] = accent; parts[10] = '" stroke-width="'; parts[11] = _getValue(tokenId, 7, 6, 14).toString(); parts[12] = '" opacity="'; parts[13] = opacity; parts[14] = '"/>';
         parts[15] = '<path d="M60,'; parts[16] = (wy + _getValue(tokenId, 8, 20, 40)).toString(); parts[17] = ' Q130,'; parts[18] = (wy - 60).toString(); parts[19] = ' 200,'; parts[20] = (wy + _getValue(tokenId, 8, 20, 40)).toString(); parts[21] = ' T340,'; parts[22] = (wy + _getValue(tokenId, 8, 20, 40)).toString(); parts[23] = '" fill="none" stroke="'; parts[24] = accent; parts[25] = '" stroke-width="'; parts[26] = _getValue(tokenId, 9, 3, 8).toString(); parts[27] = '" opacity="0.3"/>';
         return string(abi.encodePacked(parts[0],parts[1],parts[2],parts[3],parts[4],parts[5],parts[6],parts[7],parts[8],parts[9],parts[10],parts[11],parts[12],parts[13],parts[14],parts[15],parts[16],parts[17],parts[18],parts[19],parts[20],parts[21],parts[22],parts[23],parts[24],parts[25],parts[26],parts[27]));
     }
 
     function _getDecorativeSVG(uint256 tokenId) private view returns (string memory) {
         string memory accent = _getAccent(tokenId);
         uint256 count = _getValue(tokenId, 10, 3, 8);
         string memory dots;
         for (uint256 i = 0; i < count; i++) {
             uint256 cx = _getValue(tokenId, 11 + i * 2, 30, 370);
             uint256 cy = _getValue(tokenId, 12 + i * 2, 30, 370);
             uint256 r = _getValue(tokenId, 13 + i * 2, 3, 8);
             if (uint256(uint128(int128(int256(cx) - 200))) < 80 && uint256(uint128(int128(int256(cy) - 200))) < 80) {
                 cx = cx > 200 ? cx + 60 : (cx < 60 ? cx + 60 : cx);
                 cy = cy > 200 ? cy + 60 : (cy < 60 ? cy + 60 : cy);
             }
             dots = string(abi.encodePacked(dots, '<circle cx="', cx.toString(), '" cy="', cy.toString(), '" r="', r.toString(), '" fill="', accent, '" opacity="0.5"/>'));
         }
         return dots;
     }
 
     function _getRingSVG(uint256 tokenId) private view returns (string memory) {
         string memory accent = _getAccent(tokenId);
         uint256 r = _getValue(tokenId, 20, 120, 180);
         uint256 sw = _getValue(tokenId, 21, 1, 4);
         return string(abi.encodePacked(
             '<circle cx="200" cy="200" r="', r.toString(), '" fill="none" stroke="', accent, '" stroke-width="', sw.toString(), '" opacity="0.15"/>'
         ));
     }
 
     /* ---------- Math helpers ---------- */
 
     function _cos(uint256 angle) private pure returns (int256) {
         if (angle == 0) return 1000; if (angle == 45) return 707; if (angle == 90) return 0;
         if (angle == 135) return -707; if (angle == 180) return -1000; if (angle == 225) return -707;
         if (angle == 270) return 0; if (angle == 315) return 707;
         return 1000;
     }
 
     function _sin(uint256 angle) private pure returns (int256) {
         if (angle == 0) return 0; if (angle == 45) return 707; if (angle == 90) return 1000;
         if (angle == 135) return 707; if (angle == 180) return 0; if (angle == 225) return -707;
         if (angle == 270) return -1000; if (angle == 315) return -707;
         return 0;
     }
 
     /* ---------- Admin ---------- */
 
     function setMintPrice(uint256 _price) external onlyOwner { mintPrice = _price; }
     function setMaxPerWallet(uint256 _max) external onlyOwner { maxPerWallet = _max; }
     function setRoyaltyRecipient(address _r) external onlyOwner { royaltyRecipient = _r; }
     function setProjectDescription(string calldata _d) external onlyOwner { projectDescription = _d; }
 
     function withdraw() external onlyOwner {
         uint256 balance = address(this).balance;
         (bool sent, ) = payable(royaltyRecipient).call{value: balance}("");
         require(sent, "Withdraw failed");
     }
 
     function totalSupply() external view returns (uint256) { return totalMinted; }
 }
