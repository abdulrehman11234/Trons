// SPDX-License-Identifier: MIT
pragma solidity ^0.5.10;

/*
 Mainnet TRC20 Token - TRNX
 --------------------------------
 Name: Trons
 Symbol: TRNX
 Decimals: 6
 Initial Supply: 1,000,000,000 (1 Billion)
 Validity: Lifetime
 Transfer Limit: 14 (normal wallets)
 Mint / Burn: Enabled
 Whitelist: Exchanges / Gateways
 Tradeable / Swappable
 Convertable (Gateway-based)
*/

contract TRNXToken {

    string public name = "Trons";
    string public symbol = "TRNX";
    uint8 public decimals = 6;
    uint256 public totalSupply;

    address public owner;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // Transfer limit
    mapping(address => uint256) public transferCount;
    uint256 public constant MAX_TRANSFERS = 14;

    // Whitelist (Exchange / Gateway / Liquidity wallets)
    mapping(address => bool) public isWhitelisted;

    // EVENTS
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event WhitelistUpdated(address indexed wallet, bool status);

    // Convert event (IMPORTANT)
    event Converted(address indexed user, uint256 amount, string target);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // ================= CONSTRUCTOR =================
    constructor(uint256 _initialSupply) public {
        owner = msg.sender;

        totalSupply = _initialSupply * 10**uint256(decimals);
        balances[owner] = totalSupply;

        // Owner always whitelisted
        isWhitelisted[owner] = true;

        emit Transfer(address(0), owner, totalSupply);
    }

    // ================= TRC20 STANDARD =================

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowances[from][msg.sender] >= amount, "Allowance exceeded");
        allowances[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    // ================= INTERNAL TRANSFER =================

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Zero address");
        require(balances[from] >= amount, "Insufficient balance");

        // 14-transfer rule only for non-whitelisted wallets
        if (!isWhitelisted[from]) {
            require(transferCount[from] < MAX_TRANSFERS, "14 transfers limit reached");
            transferCount[from]++;
        }

        balances[from] -= amount;
        balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    // ================= BURN =================

    function burn(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    // ================= MINT =================

    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Zero address");

        totalSupply += amount;
        balances[to] += amount;

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    // ================= CONVERT (GATEWAY-BASED) =================
    // Tokens are burned and conversion is handled off-chain
    function convert(uint256 amount, string calldata target) external {
        require(amount > 0, "Amount must be > 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Converted(msg.sender, amount, target);
        emit Transfer(msg.sender, address(0), amount);
    }

    // ================= WHITELIST =================

    function addToWhitelist(address wallet) external onlyOwner {
        isWhitelisted[wallet] = true;
        emit WhitelistUpdated(wallet, true);
    }

    function removeFromWhitelist(address wallet) external onlyOwner {
        isWhitelisted[wallet] = false;
        emit WhitelistUpdated(wallet, false);
    }

    // ================= OWNERSHIP =================

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        isWhitelisted[newOwner] = true;
    }
}