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

import {BonsaiTest} from "bonsai/BonsaiTest.sol";
import {IBonsaiRelay} from "bonsai/IBonsaiRelay.sol";
import {MERC20} from "contracts/MERC20.sol";

import "forge-std/console2.sol";

contract MERC20Test is BonsaiTest {
    
    MERC20 public merc20;
    
    function setUp() public withRelay {
        merc20 = new MERC20(
            "blah",
            "BLAH",
            18,
            queryImageId('FIBONACCI'),
            IBonsaiRelay(bonsaiRelay));
    }

    function _mint(address to, uint256 amount) internal {
        // // Anticipate a callback request to the relay
        vm.expectCall(address(bonsaiRelay), abi.encodeWithSelector(IBonsaiRelay.requestCallback.selector));
        // Request the callback
        merc20.mint(to, amount);

        // Anticipate a callback invocation on the starter contract
        vm.expectCall(address(merc20), abi.encodeWithSelector(MERC20.updateBalance.selector));
        // Relay the solution as a callback
        runPendingCallbackRequest();

        assertEq(merc20.balanceOf(address(to)), amount);
    }

    function testMint() public {
        _mint(address(this), 1 );
    }

    function testBurn() public {
        _mint(address(this), 1);
        // // Anticipate a callback request to the relay
        vm.expectCall(address(bonsaiRelay), abi.encodeWithSelector(IBonsaiRelay.requestCallback.selector));
        // Request the callback
        merc20.burn(address(this), 1);

        // Anticipate a callback invocation on the starter contract
        vm.expectCall(address(merc20), abi.encodeWithSelector(MERC20.updateBalance.selector));
        // Relay the solution as a callback
        runPendingCallbackRequest();

        
        uint256 result = merc20.balanceOf(address(this));
        assertEq(result, 0);
    }

    function testTransfer() public{
        _mint(address(this), 1);
        
        merc20.transfer(address(0x1), 1);
        
        // TODO: INVESTIGATE HOW WE CAN MAKE THIS APPROVAL MORE AUTOMATIC
        merc20.approve(address(bonsaiRelay), type(uint256).max);
        runPendingCallbackRequest();

        assertEq(merc20.balanceOf(address(this)), 0);
        assertEq(merc20.balanceOf(address(0x1)), 1);
    }
}
