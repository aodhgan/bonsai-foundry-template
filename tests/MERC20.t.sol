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
    function setUp() public withRelay {}

    function testMockCall() public {
        console2.log("queryImageId('MERC20')");
        console2.logBytes32(queryImageId('MERC20'));

        // // Deploy a new starter instance
        MERC20 merc20 = new MERC20(
            "blah",
            "BLAH",
            18,
            queryImageId('FIBONACCI'),
            IBonsaiRelay(bonsaiRelay));

        // // Anticipate a callback request to the relay
        vm.expectCall(address(bonsaiRelay), abi.encodeWithSelector(IBonsaiRelay.requestCallback.selector));
        // Request the callback
        merc20.startMint(address(this), 1);

        // Anticipate a callback invocation on the starter contract
        vm.expectCall(address(merc20), abi.encodeWithSelector(MERC20.completeMint.selector));
        // Relay the solution as a callback
        runPendingCallbackRequest();

        // Validate the Fibonacci solution value
        uint256 result = merc20.balanceOf(address(this));
        assertEq(result, 1);
    }
}
