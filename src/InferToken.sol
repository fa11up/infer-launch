// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title InferToken (Inference Backed Endogenous Financial Reserve, INFER)
/// @notice A plain ERC-20 with a fixed supply of 1,000,000,000 INFER, minted once to the deployer (the launch
/// factory) in the constructor. No owner, no mint or burn after construction, no fee or rule on transfer.
contract InferToken is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000e18;

    constructor() ERC20("Inference Backed Endogenous Financial Reserve", "INFER") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}
