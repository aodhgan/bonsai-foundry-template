// Copyright 2023 RISC Zero, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {IBonsaiRelay} from "bonsai/IBonsaiRelay.sol";
import {BonsaiCallbackReceiver} from "bonsai/BonsaiCallbackReceiver.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";

/// @title A starter application using Bonsai through the on-chain relay.
/// @dev This contract demonstrates one pattern for offloading the computation of an expensive
//       or difficult to implement function to a RISC Zero guest running on Bonsai.
contract MERC20 is BonsaiCallbackReceiver, ERC20 {

    bool public locked;

    /// @notice Image ID of the only zkVM binary to accept callbacks from.
    bytes32 public immutable mERC20ImageId;

    bytes32 public currentRoot;

    uint64 private constant BONSAI_CALLBACK_GAS_LIMIT = 200000;

    modifier onlyUnlocked() {
        require(!locked, "Contract is locked");
        _;
    }
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bytes32 _mERC20ImageId,
        IBonsaiRelay bonsaiRelay
    ) 
    ERC20(_name, _symbol, _decimals)
    BonsaiCallbackReceiver(bonsaiRelay) {
        mERC20ImageId = _mERC20ImageId;
    }

    function startMint(address to, uint256 amount) external onlyUnlocked(){
        // lock
        locked = true;

        // now ask bonsai to generate updated merkle tree
        bonsaiRelay.requestCallback(
            mERC20ImageId, abi.encode(to, amount), address(this), this.completeMint.selector, BONSAI_CALLBACK_GAS_LIMIT
        );
    }

    function completeMint(address to, uint256 amount) external onlyBonsaiCallback(mERC20ImageId){     
        _mint(to, amount);
        // currentRoot = newRoot;
        locked = false;
    }
}
