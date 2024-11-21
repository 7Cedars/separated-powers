// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import { SeparatedPowers } from "../../src/SeparatedPowers.sol";
import { TestSetupImplementations } from "../TestSetup.t.sol";
import { Law } from "../../src/Law.sol";
import { OpenAction } from "../../src/implementations/laws/executive/OpenAction.sol";

//////////////////////////////////////////////////
//              BESPOKE LAWS                    //
//////////////////////////////////////////////////


//////////////////////////////////////////////////
//              ELECTORAL LAWS                  //
//////////////////////////////////////////////////
contract DeployTest is TestSetupImplementations {
    using ShortStrings for *;

    function testDeploy() public {
        Law lawMock = new OpenAction("OpenAction Mock", "This is a mock of the open action law contract", address(123));

        string memory lawMockName = lawMock.name().toString();
        string memory lawMockDescription = lawMock.description();

        assertEq(lawMockName, "OpenAction Mock");
        assertEq(lawMockDescription, "This is a mock of the open action law contract");
        assertEq(lawMock.separatedPowers(), address(123));
    }

    function testDeployEmitsEvent() public {
        vm.expectEmit(false, false, false, false);
        emit Law__Initialized(address(0));
        Law lawMock = new OpenAction("OpenAction Mock", "This is a mock of the open action law contract", address(123));
    }
}

//////////////////////////////////////////////////
//              EXECUTIVE LAWS                  //
//////////////////////////////////////////////////

