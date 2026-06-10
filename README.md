# Chain Gems · 全链上生成艺术 NFT

> **已部署到 BSC 主网**  
> 合约地址: [0xFdCF68F1A9F4AB335c63A45FdCAB9515CaeED9b5](https://bscscan.com/address/0xFdCF68F1A9F4AB335c63A45FdCAB9515CaeED9b5)  
> 铸造页面: 部署后可见

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| index.html | 铸造 DApp 前端，连接 MetaMask 即可铸造 |
| ChainCollectibles.sol | ERC-721 合约，含链上 SVG 生成 |
| deployment.json | 合约部署信息 |
| README.md | 项目说明 |

## 🚀 部署到 GitHub Pages

1. 打开 [github.com/new](https://github.com/new)，创建新仓库
   - 仓库名: chain-gems（或其他名字）
   - 设为 **Public**
   - 不要勾选任何初始化选项
2. 创建后，在仓库页面点击 **uploading an existing file**
3. 将本文件夹全部 4 个文件拖入上传框
4. 点 **Commit changes**
5. 去仓库 Settings → Pages → 选 main 分支 → / (root) 目录 → Save
6. 等 1-2 分钟，你的铸造页面就上线啦！

**上线后访问地址:** https://你的用户名.github.io/仓库名/

## 🪙 如何使用

1. 浏览器打开上线后的页面
2. 安装 [MetaMask](https://metamask.io/) 钱包
3. 切换到 BSC 主网（页面会自动提示切换）
4. 确保钱包里有少量 BNB 作为 Gas 费
5. 选择数量，点击「铸造」，确认交易
6. 铸造的 NFT 可在 OpenSea 上交易

## 📊 合约信息

- 名称: Chain Gems Genesis
- 总量: 500 枚
- 铸造价: 0.001 BNB/枚
- 版税: 5%（二级市场自动收取）
- 特点: 全链上生成 SVG，零外部依赖
