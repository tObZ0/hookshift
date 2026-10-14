// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Single-owner testnet treasury. Not audited. Do not use with real funds.
/// @dev The offchain agent may suggest proposals, but cannot transfer funds.
contract HookShiftTreasury {
    address public owner;
    uint256 public immutable delay;
    uint256 public immutable dailyLimitBps;
    bool public paused;
    uint256 public nextId;
    uint256 public spentToday;
    uint256 public dayIndex;
    mapping(address => bool) public allowedRecipient;

    struct Proposal {
        address payable recipient;
        uint256 amount;
        uint256 executeAfter;
        bool executed;
        bool cancelled;
    }
    mapping(uint256 => Proposal) public proposals;
    bool private entered;

    event Deposited(address indexed sender, uint256 amount);
    event RecipientAllowed(address indexed recipient, bool allowed);
    event Proposed(uint256 indexed id, address indexed recipient, uint256 amount, uint256 executeAfter);
    event Executed(uint256 indexed id, address indexed recipient, uint256 amount);
    event Cancelled(uint256 indexed id);
    event Paused(bool paused);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() { require(msg.sender == owner, "owner only"); _; }
    modifier nonReentrant() { require(!entered, "reentrant"); entered = true; _; entered = false; }

    constructor(address initialOwner, uint256 executionDelay, uint256 dailyBps) {
        require(initialOwner != address(0), "zero owner");
        require(executionDelay >= 1 hours, "delay too short");
        require(dailyBps > 0 && dailyBps <= 3000, "limit exceeds 30%");
        owner = initialOwner;
        delay = executionDelay;
        dailyLimitBps = dailyBps;
        dayIndex = block.timestamp / 1 days;
    }
    receive() external payable { emit Deposited(msg.sender, msg.value); }

    function setRecipient(address recipient, bool allowed) external onlyOwner {
        require(recipient != address(0), "zero recipient");
        allowedRecipient[recipient] = allowed;
        emit RecipientAllowed(recipient, allowed);
    }
    function setPaused(bool value) external onlyOwner {
        paused = value;
        emit Paused(value);
    }
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    function propose(address payable recipient, uint256 amount) external onlyOwner returns (uint256 id) {
        require(!paused, "paused");
        require(allowedRecipient[recipient], "recipient not allowed");
        require(amount > 0, "zero amount");
        require(amount <= address(this).balance, "insufficient balance");
        id = ++nextId;
        proposals[id] = Proposal(recipient, amount, block.timestamp + delay, false, false);
        emit Proposed(id, recipient, amount, block.timestamp + delay);
    }
    function cancel(uint256 id) external onlyOwner {
        Proposal storage proposal = proposals[id];
        require(proposal.executeAfter != 0 && !proposal.executed && !proposal.cancelled, "not pending");
        proposal.cancelled = true;
        emit Cancelled(id);
    }
    function execute(uint256 id) external onlyOwner nonReentrant {
        require(!paused, "paused");
        Proposal storage proposal = proposals[id];
        require(proposal.executeAfter != 0 && !proposal.executed && !proposal.cancelled, "not pending");
        require(block.timestamp >= proposal.executeAfter, "timelocked");
        require(allowedRecipient[proposal.recipient], "recipient not allowed");
        uint256 today = block.timestamp / 1 days;
        if (today != dayIndex) { dayIndex = today; spentToday = 0; }
        // Limit is based on the treasury balance at execution, inclusive of today's spending.
        uint256 cap = (address(this).balance + spentToday) * dailyLimitBps / 10000;
        require(spentToday + proposal.amount <= cap, "daily cap exceeded");
        require(proposal.amount <= address(this).balance, "insufficient balance");
        spentToday += proposal.amount;
        proposal.executed = true;
        (bool ok,) = proposal.recipient.call{value: proposal.amount}("");
        require(ok, "transfer failed");
        emit Executed(id, proposal.recipient, proposal.amount);
    }
}
