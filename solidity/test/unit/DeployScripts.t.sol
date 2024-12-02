// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import { SeparatedPowers } from "../../src/SeparatedPowers.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { DeployAlignedGrants } from "../../script/DeployAlignedGrants.s.sol";
import { AlignedGrants } from "../../src/implementations/daos/aligned-grants/AlignedGrants.sol";


//////////////////////////////////////////////////
//                  SETUP                       //
//////////////////////////////////////////////////


//////////////////////////////////////////////////
//                  TESTS                       //
//////////////////////////////////////////////////
contract DeployAlignedGrantsTest is Test {
    using ShortStrings for *;

    DeployAlignedGrants deployAlignedGrants = new DeployAlignedGrants();

    function testDeployScriptAlignedGrants() public {
        (
          AlignedGrants alignedGrants, 
          address[] memory laws,
          uint32[] memory allowedRoles,
          ILaw.LawConfig[] memory lawConfigs,
          uint32[] memory constituentRoles,
          address[] memory constituentAccounts
          ) = deployAlignedGrants.run();
    }

    // function testDeployEmitsEvent() public {
    //     vm.expectEmit(false, false, false, false);
    //     emit Law__Initialized(address(0));
    //     Law lawMock = new OpenAction("OpenAction Mock", "This is a mock of the open action law contract", address(123));
    // }
}
