// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MessageBoard
 * @notice 链上留言板 —— 每条留言附带作者的链下签名，合约验证签名后才记录。
 *
 * 工作流程：
 *   1. 用户在链下用私钥对 (消息内容 + nonce) 签名
 *   2. 调用 postMessage() 提交消息内容和签名
 *   3. 合约用 ecrecover 恢复签名地址，作为消息作者
 *
 * 优势：不依赖 msg.sender —— 任何人都可以「代发」一条由作者签名的留言，
 *       这也意味着 gas 费可以由第三方支付（元交易）。
 *
 * 安全提醒：
 *   - 签名前务必检查 nonce，避免重放攻击
 *   - 生产环境建议使用 EIP-712 结构化签名（更安全、用户可读）
 */

contract MessageBoard {
    // ============ 数据结构 ============

    struct Message {
        address author;   // 签名者地址（消息作者）
        string  content;  // 留言内容
        uint256 timestamp; // 上链时间戳
        uint256 nonce;    // 作者的第几条留言（防重放）
    }

    // ============ 状态变量 ============

    Message[] private _messages;                       // 所有留言
    mapping(address => uint256) private _nonces;       // 每个地址的当前 nonce

    // ============ 事件 ============

    /// @notice 新留言写入时触发
    /// @param id       留言索引
    /// @param author   签名者地址
    /// @param content  留言内容
    /// @param timestamp 上链时间
    event MessagePosted(
        uint256 indexed id,
        address indexed author,
        string content,
        uint256 timestamp
    );

    // ============ 核心函数 ============

    /**
     * @notice 发布一条留言（需要链下签名）
     * @param content 留言文本内容
     * @param v       签名 v（27 或 28）
     * @param r       签名 r
     * @param s       签名 s
     *
     * 签名消息的格式（链下构造）：
     *   messageHash = keccak256(abi.encodePacked(content, nonce))
     *   然后对 messageHash 用个人私钥签名
     *
     * 合约侧：用 ecrecover 从签名中恢复出作者地址
     */
    function postMessage(
        string calldata content,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(bytes(content).length > 0, "MessageBoard: content cannot be empty");
        require(bytes(content).length <= 280, "MessageBoard: content too long (max 280 chars)");

        // 构造消息摘要：等同于链下签名的内容
        bytes32 messageHash = keccak256(
            abi.encodePacked(content, _nonces[msg.sender])
        );

        /// @solidity memory-safe-assembly
        // 添加以太坊签名前缀 \x19Ethereum Signed Message:\n32
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        // 从签名恢复地址
        address author = ecrecover(ethSignedHash, v, r, s);
        require(author != address(0), "MessageBoard: invalid signature");

        // 记录留言
        _messages.push(Message({
            author:    author,
            content:   content,
            timestamp: block.timestamp,
            nonce:     _nonces[author]
        }));

        uint256 messageId = _messages.length - 1;

        // 递增作者的 nonce（防重放）
        _nonces[author]++;

        emit MessagePosted(messageId, author, content, block.timestamp);
    }

    // ============ 查询函数 ============

    /// @notice 获取留言总数
    function getMessageCount() external view returns (uint256) {
        return _messages.length;
    }

    /// @notice 按索引获取一条留言
    /// @param index 留言索引
    function getMessage(uint256 index) external view returns (Message memory) {
        require(index < _messages.length, "MessageBoard: index out of bounds");
        return _messages[index];
    }

    /**
     * @notice 批量获取留言（适合分页）
     * @param offset 起始索引
     * @param limit  最大条数
     * @return messages 留言数组
     * @return total   总留言数
     */
    function getMessages(
        uint256 offset,
        uint256 limit
    )
        external
        view
        returns (Message[] memory messages, uint256 total)
    {
        total = _messages.length;
        if (offset >= total) {
            return (new Message[](0), total);
        }

        uint256 end = offset + limit;
        if (end > total) {
            end = total;
        }

        uint256 count = end - offset;
        messages = new Message[](count);
        for (uint256 i = 0; i < count; i++) {
            messages[i] = _messages[offset + i];
        }
    }

    /// @notice 查询某个地址的当前 nonce（签名时需要用到）
    function getNonce(address author) external view returns (uint256) {
        return _nonces[author];
    }
}
