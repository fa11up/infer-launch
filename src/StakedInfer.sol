// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

/// @title StakedInfer (sINFER)
/// @notice Stake INFER, receive sINFER shares. Rewards are INFER that the Treasury buys with protocol revenue and
/// feeds in through `InferDripper`: each arrival raises `totalAssets`, so every share redeems for more INFER. No
/// INFER is ever emitted for staking, no claim step, one asset, the same model as sIMD.
///
/// - Inflation attack: OpenZeppelin's virtual shares with a 6-decimal offset (shares have 24 decimals, as sIMD's).
/// - One-block hold, sIMD's version: only a MINT stamps the holder; a transfer carries the sender's stamp to the
///   receiver, never lowering it; zero amounts stamp nothing. So a flash-loaned deposit cannot redeem in the
///   same block around a drip, the hold cannot be shed by moving shares to a fresh address, and nobody can
///   block someone else's exit by sending them dust.
/// - No owner, no pause, no rescue: sIMD reached that state by renouncing; this starts there.
contract StakedInfer is ERC4626 {
    /// @notice Block of each holder's latest share-increasing action, for the one-block hold.
    mapping(address account => uint256) public lastDepositBlock;

    error SameBlockRedeem();

    constructor(IERC20 infer) ERC20("Staked INFER", "sINFER") ERC4626(infer) {}

    function _decimalsOffset() internal pure override returns (uint8) {
        return 6;
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        if (block.number == lastDepositBlock[owner]) revert SameBlockRedeem();
        super._withdraw(caller, receiver, owner, assets, shares);
    }

    function _update(address from, address to, uint256 value) internal override {
        if (value != 0 && to != address(0)) {
            if (from == address(0)) {
                lastDepositBlock[to] = block.number;
            } else if (lastDepositBlock[from] > lastDepositBlock[to]) {
                lastDepositBlock[to] = lastDepositBlock[from];
            }
        }
        super._update(from, to, value);
    }

    /// @dev ERC-4626 requires the max views never to report an amount that would revert.
    function maxWithdraw(address owner) public view override returns (uint256) {
        return block.number == lastDepositBlock[owner] ? 0 : super.maxWithdraw(owner);
    }

    function maxRedeem(address owner) public view override returns (uint256) {
        return block.number == lastDepositBlock[owner] ? 0 : super.maxRedeem(owner);
    }
}
