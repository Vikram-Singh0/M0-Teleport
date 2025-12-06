// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

abstract contract Freezable {
    mapping(address => bool) internal _frozen;

    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);

    modifier notFrozen(address account) {
        require(!_frozen[account], "Account is frozen");
        _;
    }

    function freeze(address account) external virtual {
        _frozen[account] = true;
        emit AccountFrozen(account);
    }

    function unfreeze(address account) external virtual {
        _frozen[account] = false;
        emit AccountUnfrozen(account);
    }

    function isFrozen(address account) external view returns (bool) {
        return _frozen[account];
    }
}
