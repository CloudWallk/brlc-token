// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { IERC20Restrictable } from "./interfaces/IERC20Restrictable.sol";
import { ERC20Base } from "./ERC20Base.sol";

/**
 * @title ERC20Restrictable contract
 * @author CloudWalk Inc.
 * @notice The ERC20 token implementation that supports restriction operations
 */
abstract contract ERC20Restrictable is ERC20Base, IERC20Restrictable {
    /// @notice The mapping of the assigned purposes
    mapping(address => bytes32[]) private _purposeAssignments;

    /// @notice The mapping of the total restricted balances
    mapping(address => uint256) private _totalRestrictedBalances;

    /// @notice The mapping of the restricted purpose balances
    mapping(address => mapping(bytes32 => uint256)) private _restrictedPurposeBalances;

    // -------------------- Errors -----------------------------------

    /// @notice Thrown when the zero restriction purpose is passed to the function
    error ZeroPurpose();

    /// @notice Thrown when the transfer amount exceeds the restricted balance
    error TransferExceededRestrictedAmount();

    // -------------------- Functions --------------------------------

    /**
     * @inheritdoc IERC20Restrictable
     */
    function assignPurposes(address account, bytes32[] memory purposes) external onlyOwner {
        _purposeAssignments[account] = purposes;
        emit AssignPurposes(account, purposes, _purposeAssignments[account]);
    }

    /**
     * @inheritdoc IERC20Restrictable
     */
    function removeRestriction(address account, uint256 amount, bytes32 purpose) external onlyBlacklister {
        if (purpose == bytes32(0)) {
            revert ZeroPurpose();
        }
        if (amount == type(uint256).max) {
            amount = _restrictedPurposeBalances[account][purpose];
        }

        _restrictedPurposeBalances[account][purpose] -= amount;
        _totalRestrictedBalances[account] -= amount;

        emit RemoveRestriction(account, amount, purpose);
    }

    /**
     * @inheritdoc IERC20Restrictable
     */
    function transferWithPurpose(address to, uint256 amount, bytes32 purpose) external returns (bool) {
        if (purpose == bytes32(0)) {
            revert ZeroPurpose();
        }

        if (!super.transfer(to, amount)) {
            return false;
        }

        _totalRestrictedBalances[_msgSender()] += amount;
        _restrictedPurposeBalances[_msgSender()][purpose] += amount;

        emit TransferWithPurpose(_msgSender(), to, amount, purpose);

        return true;
    }

    /**
     * @inheritdoc IERC20Restrictable
     */
    function balanceOfRestricted(address account, bytes32 purpose) external view returns (uint256) {
        return _restrictedPurposeBalances[account][purpose];
    }

    /**
     * @inheritdoc IERC20Restrictable
     */
    function balanceOfRestricted(address account) external view returns (uint256) {
        return _totalRestrictedBalances[account];
    }

    /**
     * @inheritdoc ERC20Base
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        // Execute basic transfer logic
        super._beforeTokenTransfer(from, to, amount);

        // Execute restricted transfer logic
        uint256 restrictedBalance = _totalRestrictedBalances[from];
        if (restrictedBalance != 0) {
            uint256 purposeAmount = amount;
            bytes32[] memory purposes = _purposeAssignments[to];

            for (uint256 i = 0; i < purposes.length; i++) {
                bytes32 purpose = purposes[i];
                uint256 purposeBalance = _restrictedPurposeBalances[from][purpose];

                if (purposeBalance != 0) {
                    if (purposeBalance > purposeAmount) {
                        restrictedBalance -= purposeAmount;
                        purposeBalance -= purposeAmount;
                        purposeAmount = 0;
                    } else {
                        restrictedBalance -= purposeBalance;
                        purposeBalance = 0;
                        purposeAmount -= purposeBalance;
                    }
                    _restrictedPurposeBalances[from][purpose] = purposeBalance;
                }

                if (purposeAmount == 0) {
                    break;
                }
            }

            if (balanceOf(from) < restrictedBalance + amount) {
                revert TransferExceededRestrictedAmount();
            }

            _totalRestrictedBalances[from] = restrictedBalance;
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions
     * to add new variables without shifting down storage in the inheritance chain
     */
    uint256[47] private __gap;
}
