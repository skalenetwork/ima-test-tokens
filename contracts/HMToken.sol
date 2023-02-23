// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   HMToken.sol - SKALE Interchain Messaging Agent Test tokens
 *   Copyright (C) 2022-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

interface HMTokenInterface {

    function transferBulk(address[] calldata _tos, uint256[] calldata _values, uint256 _txId) external returns (uint256 _bulkCount);

    function approveBulk(address[] memory _spenders, uint256[] memory _values, uint256 _txId) external returns (uint256 _bulkCount);
}

contract HMToken is HMTokenInterface, AccessControlEnumerable {

    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens

    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant BULK_MAX_VALUE = 1000000000 * (10 ** 18);
    uint32  private constant BULK_MAX_COUNT = 100;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    event Approval(address owner, address spender, uint256 amount);

    event Transfer(address from, address to, uint256 amount);

    event BulkTransfer(uint256 indexed _txId, uint256 _bulkCount);
    event BulkApproval(uint256 indexed _txId, uint256 _bulkCount);

    constructor(string memory tokenName, string memory tokenSymbol) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = 18;
        _setRoleAdmin(MINTER_ROLE, MINTER_ROLE);
        _setupRole(MINTER_ROLE, 0xD2aAA00500000000000000000000000000000000);
    }

    function mint(address account, uint256 amount) external returns (bool) {
        require(hasRole(MINTER_ROLE,  msg.sender), "Sender is not a Minter");
        _mint(account, amount);
        return true;
    }

    /**
     * @dev burn - destroys token on msg sender
     *
     * NEED TO HAVE THIS FUNCTION ON SKALE-CHAIN
     *
     * @param amount - amount of tokens 
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool success) {
        success = _transferQuiet(recipient, amount);
        require(success, "Transfer didn't succeed");
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender] - amount
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] - subtractedValue
        );
        return true;
    }

    function transferBulk(address[] memory _tos, uint256[] memory _values, uint256 _txId) public override returns (uint256 _bulkCount) {
        require(_tos.length == _values.length, "Amount of recipients and values don't match");
        require(_tos.length < BULK_MAX_COUNT, "Too many recipients");

        uint256 _bulkValue = 0;
        for (uint j = 0; j < _tos.length; ++j) {
            _bulkValue = _bulkValue + _values[j];
        }
        require(_bulkValue < BULK_MAX_VALUE, "Bulk value too high");

        bool _success;
        for (uint i = 0; i < _tos.length; ++i) {
            _success = _transferQuiet(_tos[i], _values[i]);
            if (_success) {
                _bulkCount = _bulkCount + 1;
            }
        }
        emit BulkTransfer(_txId, _bulkCount);
        return _bulkCount;
    }

    function approveBulk(address[] memory _spenders, uint256[] memory _values, uint256 _txId) public override returns (uint256 _bulkCount) {
        require(_spenders.length == _values.length, "Amount of spenders and values don't match");
        require(_spenders.length < BULK_MAX_COUNT, "Too many spenders");

        uint256 _bulkValue = 0;
        for (uint j = 0; j < _spenders.length; ++j) {
            _bulkValue = _bulkValue + _values[j];
        }
        require(_bulkValue < BULK_MAX_VALUE, "Bulk value too high");

        bool _success;
        for (uint i = 0; i < _spenders.length; ++i) {
            _success = increaseAllowance(_spenders[i], _values[i]);
            if (_success) {
                _bulkCount = _bulkCount + 1;
            }
        }
        emit BulkApproval(_txId, _bulkCount);
        return _bulkCount;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    // Like transfer, but fails quietly.
    function _transferQuiet(address _to, uint256 _value) internal returns (bool success) {
        if (_to == address(0)) return false; // Preclude burning tokens to uninitialized address.
        if (_to == address(this)) return false; // Preclude sending tokens to the contract.
        if (_balances[msg.sender] < _value) return false;

        _balances[msg.sender] = _balances[msg.sender] - _value;
        _balances[_to] = _balances[_to] + _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}