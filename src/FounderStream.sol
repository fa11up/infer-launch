// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title FounderStream
/// @notice The founder allocation, released linearly over 12 months from launch with a 30-day cliff. No owner,
/// no admin, nothing to change: anyone may call `release`, and it only ever pays the fixed beneficiary.
///
/// The clock starts at construction (the launch block). Nothing is releasable before day 30; from day 30 the
/// vested amount is the straight line from day 0, so the cliff releases one month's worth at once, and the whole
/// allocation is vested at day 365. The INFER itself arrives from the GenesisSplitter in or after the launch
/// block; a release never pays more than the contract holds.
contract FounderStream {
    using SafeERC20 for IERC20;

    uint256 public constant genesisAllocation = 70_000_000e18;
    uint256 public constant CLIFF = 30 days;
    uint256 public constant DURATION = 365 days;

    IERC20 public immutable token;
    address public immutable beneficiary;
    uint64 public immutable start;
    uint256 public released;

    event Released(uint256 amount);

    error ZeroAddress();
    error NothingToRelease();

    constructor(address token_, address beneficiary_) {
        if (token_ == address(0) || beneficiary_ == address(0)) revert ZeroAddress();
        token = IERC20(token_);
        beneficiary = beneficiary_;
        start = uint64(block.timestamp);
    }

    /// @notice INFER vested so far, whether or not it has been released.
    function vested() public view returns (uint256) {
        uint256 elapsed = block.timestamp - start;
        if (elapsed < CLIFF) return 0;
        if (elapsed >= DURATION) return genesisAllocation;
        return genesisAllocation * elapsed / DURATION;
    }

    /// @notice What `release` would pay now.
    /// After the stream ends it is everything held, so nothing sent here by mistake is stranded.
    function releasable() public view returns (uint256) {
        uint256 held = token.balanceOf(address(this));
        if (block.timestamp - start >= DURATION) return held;
        uint256 due = vested() - released;
        return due < held ? due : held;
    }

    /// @notice Pay everything vested and unreleased to the beneficiary. Anyone.
    function release() external returns (uint256 amount) {
        amount = releasable();
        if (amount == 0) revert NothingToRelease();
        released += amount;
        token.safeTransfer(beneficiary, amount);
        emit Released(amount);
    }
}
