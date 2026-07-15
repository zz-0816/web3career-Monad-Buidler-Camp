# 留言板智能合约 — MessageBoard

## 🏆 Week 1 作品提交

### 1. 作品链接

> GitHub: https://github.com/zz-0816/web3career-Monad-Buidler-Camp

### 2. Demo 说明

**项目名称**：链上留言板（MessageBoard）

**核心功能**：
- 双版本合约：签名验证版（ECDSA 链下签名 + 链上 ecrecover 恢复）和模拟测试版（msg.sender 直签）
- 浏览器端签名工具（ethers.js v6），支持 MetaMask/Rabby 连接，链下对消息签名后提交链上验证
- nonce 防重放、分页查询、280 字符留言限制

**技术栈**：Solidity ^0.8.20 | ethers.js v6 | Remix IDE

**测试环境**：Remix VM (Cancun + EVM Version paris)

**测试截图**：
```
1. Remix 编译 + 部署 MessageBoard_Simulator
2. postMessage("hello monad") → 交易成功
3. getMessage(0) → 返回 author + content + timestamp
```

### 3. 方向选择

**Tech（研发）**

### 4. 简历一句话

> 独立设计并实现基于 ECDSA 签名的链上留言板智能合约，含完整的前端签名工具和防重放机制，在 Remix 模拟链上完成部署验证。

### 5. Week 2 计划

- Monad Testnet 真实部署（解决 MetaMask 连接问题）
- AI Agent + 智能合约交互原型
- ERC-20 / ERC-721 合约实战

---

## 📋 Prompt 记录

### 原始 Prompt（2026-07-14）

> 你现在作为我的 solidity 智能合约开发助理，我需要你使用 solidity、html、css、js、python 开发一项名为留言板的智能合约，工具是 remix，其中要对留言人进行签名，请时刻记住考虑好行为避免幻觉产生后进行谨慎修改。

### Prompt 更新记录

| 时间 | Prompt 摘要 |
|------|------------|
| 7/14 #1 | 创建 MessageBoard 签名版合约 + sign.html 签名工具 |
| 7/14 #2 | PUSH0 报错排查 → 创建 MessageBoard_Simulator 模拟版，改 EVM Version 到 paris |
| 7/14 #3 | MetaMask 无法被 Remix 检测 → 多方案排查 → 最终用 `file://` 协议问题定位 → Python HTTP 服务器解决 |
| 7/14 #4 | 更新 README 为 Week 1 提交格式 + 创建 GitHub 仓库推送 |

---

## 📁 文件清单

| 文件 | 说明 |
|------|------|
| `MessageBoard.sol` | 签名版合约（生产级，ECDSA 验证） |
| `MessageBoard_Simulator.sol` | 模拟版合约（Remix VM 测试用） |
| `sign.html` | 链下消息签名工具（需 HTTP 服务器托管） |
| `Week1_Build_Log.md` | Week 1 完整学习记录 |
| `README.md` | 本文件 |

---

## 🔧 使用 Remix 部署 & 测试

### 环境准备

1. 访问 https://remix.ethereum.org
2. 导入 `.sol` 文件

### 模拟版测试（推荐先跑）

1. Solidity Compiler → 打开 `MessageBoard_Simulator.sol`
2. Advanced Config → **EVM Version = `paris`**（避 PUSH0 兼容问题）
3. 编译 → Deploy & Run → Environment = `Remix VM (Cancun)`
4. Deploy → `postMessage("hello monad")` → `getMessage(0)` 验证

### 签名版部署（需要真实钱包）

1. MetaMask/Rabby 连接 Monad Testnet（Chain ID: 10143）
2. 用 HTTP 服务器托管 `sign.html`（`file://` 协议下 MetaMask 不注入）：
   ```bash
   python3 -m http.server 8080
   ```
3. 浏览器访问 `http://localhost:8080/sign.html`
4. 连接钱包 → 填入 nonce → 写留言 → 签名 → 拿到 v, r, s
5. Remix 调用 `postMessage(content, v, r, s)` 提交

---

## 🔐 签名机制说明

```
链下（用户浏览器）：
  1. 构造消息: content + nonce
  2. 计算 hash: keccak256(abi.encodePacked(content, nonce))
  3. 加以太坊前缀: "\x19Ethereum Signed Message:\n32" + hash
  4. 钱包私钥签名 → 得到 (v, r, s)

链上（合约验证）：
  1. 用同样的 content + nonce 重建 hash
  2. ecrecover(ethSignedHash, v, r, s) → 恢复出作者地址
  3. nonce 自增，防止同一签名被重放
```

---

## ⚠️ 注意事项 & 踩坑记录

| 坑 | 现象 | 解决 |
|----|------|------|
| PUSH0 不兼容 | `invalid opcode` | Solidity Compiler → EVM Version = `paris` |
| file:// 协议 | MetaMask 不注入页面 | 用 `python3 -m http.server` 起 HTTP 服务 |
| 签名按钮灰着 | 连接钱包失败导致按钮 disabled | 解耦签名按钮和连接状态 |
| 参数传错 | `incorrect data length` | 模拟版只需 content，签名版需要 content+v+r+s |
