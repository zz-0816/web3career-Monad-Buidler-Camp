# 留言板智能合约 — MessageBoard

> Monad Buidler Camp · Week 1 · Tech（研发）方向

---

## 1. 我做了什么

### 合约开发

| 文件 | 说明 | 行数 |
|------|------|------|
| `MessageBoard.sol` | ECDSA 签名验证版合约 | 134 行 |
| `MessageBoard_Simulator.sol` | msg.sender 直签版（测试用） | 60 行 |
| `sign.html` | 浏览器端链下签名工具（ethers.js v6） | 140 行 |
| `Week1_Build_Log.md` | 完整学习记录 + 踩坑 | ~300 行 |
| `README.md` | 项目文档 | 本文件 |

**合约核心逻辑**：

```
留言流程:  用户写内容 → 链下用私钥签名 → 提交签名到合约 → ecrecover 恢复地址 → 存储留言

签名格式:  keccak256(abi.encodePacked(content, nonce))  → 加 \x19Ethereum... 前缀 → 钱包签名
防重放:    每条留言 nonce 递增，同一签名只能用一次
```

### 课程笔记

- 7/8～7/14 共 7 天课程笔记（X Broadcast 转录整理）
- 涵盖：Monad 公链、AI Agent 支付、Web3 安全、EPF 协议开发、AI 编程方法论

---

## 2. 哪部分是真实链上操作

| 操作 | 环境 | 状态 |
|------|------|------|
| 合约编译 | Remix IDE | ✅ 完成 |
| 合约部署测试 | Remix VM (Cancun) 模拟链 | ✅ 完成 |
| `postMessage` / `getMessage` 调用 | Remix VM 模拟链 | ✅ 完成 |
| MetaMask 连接 Monad Testnet | — | ❌ 浏览器插件兼容问题，待解决 |
| Monad Testnet 真实部署 | — | ❌ Week 2 推进 |

> ⚠️ **诚实声明**：当前所有合约测试均在 Remix 内置模拟链（VM）上完成，尚无 Monad Testnet 真实链上交易。

---

## 3. 哪部分由 AI 辅助完成

| 产出 | AI 贡献 | 占比 |
|------|---------|------|
| `MessageBoard.sol` | AI 生成完整合约代码 | ~100% |
| `MessageBoard_Simulator.sol` | AI 根据原版简化生成 | ~100% |
| `sign.html` | AI 生成签名工具 HTML/JS | ~100% |
| `Week1_Build_Log.md` | AI 根据对话记录生成框架，人工补充 | ~70% |
| `README.md` | AI 生成，人工多次改版 | ~80% |
| 课程笔记 (zz-0816.md) | AI 转录视频并结构化 | ~90% |

---

## 4. 我做了哪些人工判断和修改

### 判断 1：PUSH0 兼容性问题

- **AI 给了「换 EVM Version 到 paris」的建议**
- **我做的判断**：先尝试了换编译器版本（0.8.19 → 0.8.34），发现无效；理解到 PUSH0 是 EVM 层面的问题，与 Solidity 版本号无关；最终采纳 AI 建议改 EVM Version
- **收获**：版本号和 EVM 目标是两个独立参数

### 判断 2：MetaMask 连接失败排查

- **AI 给了全套排查清单**（解锁钱包、关闭插件、刷新页面、无痕模式）
- **我做的判断**：逐一尝试均失败后，发现地址栏是 `file://` 协议，意识到 MetaMask 不向本地文件注入；采纳 AI 建议用 Python HTTP 服务器
- **收获**：`file://` vs `http://` 对浏览器扩展的影响

### 判断 3：双版本策略

- **AI 建议**：创建一个去掉签名验证的模拟版，方便在 Remix VM 上测试核心逻辑
- **我采纳的理由**：真实签名需要钱包，而钱包连接卡住了；先验证合约逻辑正确，再解决连接问题，分开推进效率更高

### 判断 4：合约参数传递错误

- 部署签名版时把钱包地址填到了 `v` 参数位置 → 报 `incorrect data length`
- **分析**：签名版需要 4 个参数 `(content, v, r, s)`，当前环境没有签名就硬传，参数类型不匹配
- **决定**：先切回模拟版，只传 `content` 一个参数

### 判断 5：方向选择 Tech

- 课程介绍了 Tech（研发）/ Ops（运营）/ Research（研究员）三赛道
- **我的判断**：调试合约 PUSH0 bug 时的投入感 > 读文档时的满足感；不排斥「写码 → 报错 → 定位 → 修复」循环
- **长期考虑**：纯合约岗位对新人残酷（要 3-5 年经验），可能以 Ops 为跳板切入生态，逐步积累 → 转合约开发

---

## 5. 接下来推进方向

### Week 2 目标

| 优先级 | 任务 | 状态 |
|--------|------|------|
| P0 | 解决 MetaMask 连接问题 + 部署到 Monad Testnet | 待推进 |
| P1 | ERC-20 / ERC-721 合约实战 | 待推进 |
| P2 | AI Agent + 智能合约交互原型（参考 Monagotchi） | 探索 |

### 需要帮助

1. MetaMask 浏览器插件注入问题，有同学遇到并解决了吗？
2. Monad Testnet 水龙头稳定吗？如果领不到币有其他渠道吗？

---

## 🔧 使用说明

### 模拟版测试（Remix VM）

```
1. Remix 打开 MessageBoard_Simulator.sol
2. Solidity Compiler → Advanced Config → EVM Version = paris
3. Deploy & Run → Environment = Remix VM (Cancun)
4. Deploy → postMessage("hello") → getMessage(0)
```

### 签名版部署（需要真实钱包）

```bash
# 1. 签名的 sign.html 需要 HTTP 托管（file:// 协议下 MetaMask 不注入）
cd week1 && python3 -m http.server 8080

# 2. 浏览器打开 http://localhost:8080/sign.html
# 3. 连接钱包 → 签名 → 拿到 v, r, s
# 4. Remix 调用 postMessage(content, v, r, s)
```

---

## 📋 踩坑记录

| 坑 | 根因 | 解决 |
|----|------|------|
| `invalid opcode` | Solidity 0.8.20+ 默认 PUSH0，Remix VM 不支持 | EVM Version = `paris` |
| MetaMask 无反应 | `file://` 协议下 MetaMask 不注入 JS | `python3 -m http.server` |
| `incorrect data length` | 签名版合约参数传错 | 模拟版只用 content 一个参数 |
| 签名按钮灰着 | 原代码签名按钮依赖钱包连接成功才解锁 | 改 `onclick` 逻辑解耦 |

---

## ⚠️ 安全提醒

- 合约中的 `ecrecover` 在生产环境建议替换为 OpenZeppelin 的 `ECDSA.recover`
- nonce 管理当前依赖合约存储，高并发场景需考虑 gas 优化
- 签名工具 `sign.html` 仅供学习测试，生产环境需用 EIP-712 结构化签名

---

> GitHub: https://github.com/zz-0816/web3career-Monad-Buidler-Camp
