// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console2 } from "lib/forge-std/src/Script.sol";

import { MockErc1155 } from "../../test/mocks/Erc1155Mock.sol";
import { MockErc20Votes } from "../../src/mocks/MockErc20Votes.sol";

contract DeployMocks is Script {
    /* Functions */
    function run()
        external
        returns (
            MockErc1155 mockErc1155,
            MockErc20Votes mockErc20Votes
        )
    {   
        vm.startBroadcast();
          mockErc1155 = new MockErc1155();
          mockErc20Votes = new MockErc20Votes();
        vm.stopBroadcast();

        return (
            mockErc1155, mockErc20Votes
        );
    }
}
