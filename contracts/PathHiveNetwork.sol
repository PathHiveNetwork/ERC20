pragma solidity ^0.4.25;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Role.sol";

contract PathHiveNetwork is Role, ERC20 {

    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping (address => bool) private _frozenAccount;
    mapping (address => uint) private _frozenAccountIndex;
    address[] private _frozenAccountList;
    uint256 private _totalSupply;

    bool private _paused = false;

    constructor() public {}

    function paused() public view returns(bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        if(msg.sender==owner){
            _;
        }else{
            require(!_paused);
            _;
        }
    }

    modifier whenPaused() {
        require(_paused);
        _;
    }

    function pause() public pauserAndAbove {
        require(!_paused);
        _paused = true;
        emit Paused();
    }

    function unpause() public pauserAndAbove {
        require(_paused);
        _paused = false;
        emit UnPaused();
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) public constant returns (uint256) {
        return _balances[who];
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount) public whenNotPaused returns (bool) {
        require(!_frozenAccount[msg.sender]);
        require(!_frozenAccount[to]);
        require(msg.sender != to);
        require(to != address(0));
        require(_balances[msg.sender] >= amount);
        require(amount > 0);

        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        require(!_frozenAccount[from]);
        require(!_frozenAccount[to]);
        require(to != address(0));
        require(amount > 0);
        require(_balances[from] >= amount);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(amount);
        _transfer(from, to, amount);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseApproval(address spender, uint256 addedValue) public whenNotPaused returns (bool){
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public whenNotPaused returns (bool){
        require(spender != address(0));
        uint256 oldValue = _allowed[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowed[msg.sender][spender] = 0;
        } else {
            _allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function burn(address to, uint256 amount) onlyOwner public returns (bool){
        require(amount > 0);
        require(to != address(0));
        require(amount <= _balances[to]);

        _totalSupply = _totalSupply.sub(amount);
        _balances[to] = _balances[to].sub(amount);
        emit Transfer(to, address(0), amount);
        return true;
    }

    function mint(address to, uint256 amount) public administerAndAbove returns (bool){
        require(to != address(0));
        require(amount > 0);
        _totalSupply = _totalSupply.add(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function freezeAccount(address target, bool freeze) pauserAndAbove public {
        require(target!=owner);
        require(target!=msg.sender);
        if(freeze){
            require(!isFrozenAccount(target));
            _frozenAccount[target] = freeze;
            _frozenAccountIndex[target] = _frozenAccountList.push(target) - 1;
            emit FrozenAccount(target, freeze);
        }else{
            require(isFrozenAccount(target));
            if (_frozenAccountIndex[target]==0){
                require(_frozenAccountList[0] == target);
            }
            for (uint i = _frozenAccountIndex[target]; i<_frozenAccountList.length-1; i++){
                _frozenAccountList[i] = _frozenAccountList[i+1];
                _frozenAccountIndex[_frozenAccountList[i+1]] = _frozenAccountIndex[_frozenAccountList[i+1]]-1;
            }
            delete _frozenAccountList[_frozenAccountList.length-1];
            delete _frozenAccountIndex[target];
            delete _frozenAccount[target];
            _frozenAccountList.length--;
            emit UnFrozenAccount(target, freeze);
        }
    }

    function isFrozenAccount(address who) view public returns(bool) {
        return _frozenAccount[who];
    }

    function getFrozenAccountList() view public returns(address[]) {
        return _frozenAccountList;
    }

    event Approval(address indexed tokenOwner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint amount);
    event Paused();
    event UnPaused();
    event FrozenAccount(address target, bool frozen);
    event UnFrozenAccount(address target, bool frozen);
}