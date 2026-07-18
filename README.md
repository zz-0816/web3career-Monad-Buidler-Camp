# Moss 入门指南：从 0 到第一个 PR

> 一份写给新人的实践教程。基于真实贡献经历（PR #81）编写。

---

## 目录

1. [Moss 是什么（用人话）](#1-moss-是什么用人话)
2. [环境准备](#2-环境准备)
3. [5 分钟跑起来](#3-5-分钟跑起来)
4. [项目结构速览](#4-项目结构速览)
5. [理解核心概念](#5-理解核心概念)
6. [读懂一个 Protocol（以 ERC-20 为例）](#6-读懂一个-protocol以-erc-20-为例)
7. [常见坑（FAQ）](#7-常见坑faq)
8. [下一步：选择你的第一个贡献](#8-下一步选择你的第一个贡献)

---

## 1. Moss 是什么（用人话）

你问 AI：「帮我用 1 个 MON 换成 USDC。」

AI 很聪明，但它不知道：
- Kuru 合约地址在哪
- `swap` 函数要传什么参数
- calldata 怎么编码

**Moss = AI 和区块链之间的翻译层。** 它把「我要 swap」翻译成合约能读的 calldata，把链上返回的十六进制翻译成人能看的结果。而且——**Moss 只构建交易，永不签名。** 签名是钱包的事。

---

## 2. 环境准备

```bash
# 需要 Node.js 22+ 和 pnpm 11+
node --version   # 应该 ≥ 22
npm install -g pnpm
pnpm --version   # 应该 ≥ 11
```

克隆并安装：

```bash
git clone https://github.com/nishuzumi/moss.git
cd moss
pnpm install    # 约 1-3 分钟，取决于网络
pnpm build      # 编译所有包
pnpm test       # 跑测试验证环境
```

> ⚠️ 国内用户：`pnpm install` 可能很慢，耐心等。不要 Ctrl+C 中断。

如果看到全部绿色 `Tests X passed`，环境就 OK 了。

---

## 3. 5 分钟跑起来

Moss 自带两个示例，不需要钱包，不需要代币——因为 Moss 只模拟，不签名，不花钱。

```bash
# 模拟一次 WMON wrap
pnpm --filter @themoss/example-simple-flow wrap

# 模拟一次 Kuru swap（MON → USDC）
pnpm --filter @themoss/example-simple-flow swap
```

你会看到类似输出：

```
discover → found 'system' / 'wrap'
load → params: { amount: "0.01" }
action → Capability tree built
simulate → ✅ Receipt: Wrap 0.01 MON → WMON
```

这就跑通了 Moss 的核心流程。没有花一分钱，没有签任何交易。

---

## 4. 项目结构速览

```
moss/
├── packages/
│   ├── core/                # 框架核心：Registry、Capability 树、Receipt 验证
│   ├── simulator/           # 模拟器：debug_traceCall → 有序 Change 提取
│   ├── erc/                 # ERC-20/721/1155 标准接口
│   │   ├── src/abis/        # ABI 定义
│   │   ├── src/erc20.ts     # ERC-20 Protocol（最好的学习模板）
│   │   └── test/            # 测试
│   ├── system/              # Monad Runtime、官方地址常量（USDC、WMON）
│   ├── protocols/           # 第三方协议（Kuru DEX）
│   │   ├── _template/       # 新 Protocol 模板
│   │   └── kuru/
│   └── mcp-server/          # MCP 传输层
├── docs/
│   ├── adr/                 # 架构决策记录（了解"为什么这样设计"）
│   └── protocol-onboarding.md
├── CONTEXT.md               # 领域词汇表（Capability 是什么、Verb 有哪几个）
├── CONTRIBUTING.md          # 贡献指南 + Protocol Definition of Done
└── AGENTS.md                # AI Agent 开发规则
```

**新人只需要关注三个文件**：`CONTEXT.md`、`packages/erc/src/erc20.ts`、`CONTRIBUTING.md`。

---

## 5. 理解核心概念

不需要全记住，先知道这四个词：

| 概念 | 一句话 | 类比 |
|------|--------|------|
| **Protocol** | 一个链上协议的包装盒 | Uniswap 的 SDK |
| **Capability** | 写操作（转账、兑换） | `swap()` 方法 |
| **Query** | 读操作（查余额、查报价） | `getBalance()` 方法 |
| **Receipt** | 模拟后返回的收据 | 银行流水单 |

四个 MCP 工具串联整个流程：

```
discover → load → action → simulate
  发现      加载     构建      模拟
```

---

## 6. 读懂一个 Protocol（以 ERC-20 为例）

打开 `packages/erc/src/erc20.ts`，按这个顺序读：

### 6.1 顶部：参数定义

```ts
const transferParams = {
  token:  { type: Address, description: "..." },
  to:     { type: Address, description: "..." },
  amount: { type: PositiveDecimalString, description: "..." },
} satisfies ParamsSpec;
```

`ParamsSpec` 是 Zod schema + 人类可读描述。`PositiveDecimalString` 是 Moss 内置的 Zod 类型。

### 6.2 中间：Protocol 类 + 装饰器

```ts
@Protocol({ name: "erc20", category: "token", ... })
export class ERC20 {
  @Capability({ intent: "Transfer tokens", verb: "transfer", ... })
  async transfer(params, ctx) { ... }

  @Query({ intent: "Read balance", ... })
  async balanceOf(params, ctx) { ... }

  @Receipt()
  transferReceipt(changes) { ... }
}
```

每个 `@Capability` 是一个写操作，每个 `@Query` 是一个读操作，`@Receipt` 是结果解析器。

### 6.3 底部：事件解析

```ts
function parseERC20Change(change: Change): ERC20Outcome {
  if (change.kind === "nativeTransfer") { ... }
  // decodeEventLog → Transfer / Approval
}
```

Receipt 解析器只接收 `Change[]`，输出结构化的 Outcome + 人类可读 text。

---

## 7. 常见坑（FAQ）

### Q1：`pnpm install` 报错 / 很慢？

国内网络问题。等，不要中断。如果反复失败，试试代理。

### Q2：`pnpm build` 报 `esbuild` 相关错误？

确认 Node ≥ 22，`pnpm ≥ 11`。

### Q3：我想给 ERC-20 加一个新功能，能改 `erc20.ts` 吗？

可以加新的 Capability/Query，但 **verb 必须用 Moss 的白名单**：
`transfer`, `approve`, `swap`, `wrap`, `unwrap`, `supply`, `withdraw`, `borrow`, `repay`, `stake`, `unstake`, `claim`, `mint`。不能用自定义动词。

### Q4：我要加一个新协议，ABI 怎么提供？

**ABI 不能手写。** Moss 有三种来源（ADR 0007）：
- `compiled`：foundry 编译生成
- `explorer`：从区块浏览器验证合约拉取
- `vendored`：从 OpenZeppelin 等官方包引入 + 用 viem `parseAbi` 生成

手写 `[{ type: "function", name: "transfer"... }]` 不会被接受。

### Q5：`pnpm test` 报 `z.boolean()` 相关错误？

Moss 的 Registry 会对每个参数做 metadata 校验。`z.boolean()` 必须加 `.describe("...")`，否则注册时抛 Error。

### Q6：报 `verb "xxx" is not assignable`？

你用的动词不在白名单里。查 `CONTEXT.md` 的 Verb 章节。


> *Moss 的门槛不在代码复杂度，而在「理解它的设计哲学」。读透 `erc20.ts` + `CONTEXT.md`，你就超过 90% 的观望者了。*
