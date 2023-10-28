// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @title IERC20Restrictable interface
 * @author CloudWalk Inc.
 * @notice The interface of a token that supports restriction operations
 */
interface IERC20Restrictable {
    /**
     * @notice Emitted when the restriction purposes are assigned to the account
     *
     * @param account The account the restriction purposes are assigned to
     * @param newPurposes The array of the new restriction purposes
     * @param oldPurposes The array of the old restriction purposes
     */
    event AssignPurposes(address indexed account, bytes32[] newPurposes, bytes32[] oldPurposes);

    /**
     * @notice Emitted when the restriction is updated for the account
     *
     * @param account The account the restriction is updated for
     * @param purpose The restriction purpose
     * @param balance The new restricted balance
     */
    event UpdateRestriction(address indexed account, bytes32 indexed purpose, uint256 balance);

    /**
     * @notice Assigns the restriction purposes to the account
     *
     * @param account The account to assign purposes to
     * @param purposes The purposes to assign
     */
    function assignPurposes(address account, bytes32[] memory purposes) external;

    /**
     * @notice Returns the restriction purposes assigned to the account
     *
     * @param account The account to check
     */
    function assignedPurposes(address account) external view returns (bytes32[] memory);

    /**
     * @notice Updates the restriction balance for the account
     *
     * @param account The account to update restriction for
     * @param purpose The restriction purpose
     * @param balance The new restricted balance
     */
    function updateRestriction(address account, bytes32 purpose, uint256 balance) external;

    /**
     * @notice Returns the restricted balance for the account and the restriction purpose
     *
     * @param account The account to check
     * @param purpose The restriction purpose to check (if zero, returns the total restricted balance)
     */
    function balanceOfRestricted(address account, bytes32 purpose) external view returns (uint256);
}
