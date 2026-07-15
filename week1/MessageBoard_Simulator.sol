// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MessageBoard (Simulator Edition)
 * @notice 简化版留言板 —— 直接用 msg.sender 作为留言作者，无需签名。
 *         适合 Remix VM 模拟环境下快速学习测试。
 *
 * 原版（带签名验证）见 MessageBoard.sol
 */

contract MessageBoard {
    struct Message {
        address author;
        string  content;
        uint256 timestamp;
    }

    Message[] private _messages;

    event MessagePosted(
        uint256 indexed id,
        address indexed author,
        string content,
        uint256 timestamp
    );

    /// @notice 发布留言（msg.sender 即为作者）
    function postMessage(string calldata content) external {
        require(bytes(content).length > 0, "content cannot be empty");
        require(bytes(content).length <= 280, "content too long (max 280 chars)");

        _messages.push(Message({
            author:    msg.sender,
            content:   content,
            timestamp: block.timestamp
        }));

        emit MessagePosted(_messages.length - 1, msg.sender, content, block.timestamp);
    }

    /// @notice 留言总数
    function getMessageCount() external view returns (uint256) {
        return _messages.length;
    }

    /// @notice 获取单条留言
    function getMessage(uint256 index) external view returns (Message memory) {
        require(index < _messages.length, "index out of bounds");
        return _messages[index];
    }
}
