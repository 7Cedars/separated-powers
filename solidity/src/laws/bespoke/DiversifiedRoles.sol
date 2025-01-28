 // SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and it contracts have not been audited.            ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

// note that natspecs are wip.

pragma solidity 0.8.26;

// protocol
import { Law } from "../../Law.sol";
import { SeparatedPowers } from "../../SeparatedPowers.sol";

// mocks 
import { Erc721Mock } from "../../../test/mocks/Erc721Mock.sol";
import { Erc1155Mock } from "../../../test/mocks/Erc1155Mock.sol";

// laws 
import { PresetAction } from "../executive/PresetAction.sol";
import { BespokeAction } from "../executive/BespokeAction.sol";
import { SelfDestruct } from "../modules/SelfDestruct.sol";
import { ThrottlePerAccount } from "../modules/ThrottlePerAccount.sol";
import { NftCheck } from "../modules/NftCheck.sol";
import { SelfSelect } from "../electoral/SelfSelect.sol";

// open zeppelin contracts
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

// possible to add more types later on. 
 
// NB: no checks on what kind of Erc20 token is used. This is just an example. 
contract Members is Law {
    error Members__MemberAlreadyExists(address account);
    error Members__MemberNonExistent(address account);

    // see for country codes IBAN: https://www.iban.com/country-codes
    struct Member {
        uint16 nationality;
        uint16 countryOfResidence;
        int64  dateOfBirth; // NB: can also go into minus for before 1970.  https://en.wikipedia.org/wiki/Unix_time#:~:text=A%20signed%2032%2Dbit%20value,Tuesday%202038%2D01%2D19.
    }
    mapping(address => Member) public members; 

    event Members__Added(address indexed account);
    event Members__Removed(address indexed account);

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        inputParams[0] = _dataType("address"); // account
        inputParams[1] = _dataType("uint16");  // nationality
        inputParams[2] = _dataType("uint16");  // country of residence 
        inputParams[3] = _dataType("int64"); // DoB
        inputParams[4] = _dataType("bool"); // add ? (if false: remove)  
      }
   
    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view 
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {   
        // step 0: decode law calldata
        (address account, , , , bool add) = abi.decode(lawCalldata, (address, uint16, uint16, int64, bool));
        
        // step 1: run additional checks 
        if (add && members[account].nationality != 0) {
            revert Members__MemberAlreadyExists(account);            
        } 
        if (!add && members[account].nationality == 0) {
            revert Members__MemberNonExistent(account);
        } 

        // step 2: create arrays 
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // step 3: fill out arrays with data - no action should be taken by protocol. 
        targets[0] = address(1);
        stateChange = lawCalldata; 

        // step 4: return data 
        return (targets, values, calldatas, stateChange);
    }

    // add or remove member from state mapping in law. 
    function _changeStateVariables(bytes memory stateChange) internal override {
        (address account, uint16 nationality, uint16 countryOfResidence, int64 DoB, bool add) = abi.decode(stateChange, (address, uint16, uint16, int64, bool));

        if (add) {
            members[account] = Member(nationality, countryOfResidence, DoB); 
            emit Members__Added(account);            
        } else {
            members[account] = Member(0, 0, 0);
            emit Members__Removed(account);
        }
    }
}

contract RoleByKyc is SelfSelect {
    error RoleByKyc__NotEligible(); 

    uint16[] public nationalities; 
    uint16[] public countryOfResidences; 
    int64 public olderThan; // in seconds 
    int64 public youngerThan; // in seconds
    address public members;

    constructor(
        // standard
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        // self select
        uint32 roleId_, 
        // filter 
        uint16[] memory nationalities_,
        uint16[] memory countryOfResidences_, 
        int64 olderThan_, // in seconds 
        int64 youngerThan_, // in seconds
        // members state law
        address members_  
        ) 
        SelfSelect(name_, description_, separatedPowers_, allowedRole_, config_, roleId_) { 
            nationalities = nationalities_;
            countryOfResidences = countryOfResidences_;
            olderThan = olderThan_;
            youngerThan = youngerThan_;
        }

    function simulateLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view 
        override
        virtual
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // note that each initiates to 'false'. 
        bool nationalityOk;
        bool residencyOk; 
        bool oldEnough; 
        bool youngEnough; 
        (uint16 nationality, uint16 countryOfResidence, int64 DoB) = Members(members).members(initiator);

        // step 0: check nationalities  
        if (nationalities.length > 0) {
            for (uint i = 0; i < nationalities.length; i++) {
                if (nationality == nationalities[i]) { nationalityOk = true; break; } 
            }
        } else {
            nationalityOk = true; 
        }

        // step 1: check country of residences
        if (countryOfResidences.length > 0) {
            for (uint i = 0; i < countryOfResidences.length; i++) {
                if (countryOfResidence == countryOfResidences[i]) { residencyOk = true; break; } 
            }
        } else {
            residencyOk = true;
        }
        
        // step 2: check if individual is old enough
        if (olderThan > 0) { 
            if (uint64(DoB) < (uint64(block.timestamp) - uint64(olderThan))) { oldEnough = true; }
        } else {
            oldEnough = true;
        }

        // step 3: check if individual is young enough
        if (youngerThan > 0) {
            if (uint64(DoB) > (uint64(block.timestamp) - uint64(youngerThan))) { youngEnough = true; }
        } else {
            youngEnough = true;
        }

        // step 4: revert if any of the checks fail
        if (!nationalityOk || !residencyOk || !oldEnough || !youngEnough) {
            revert RoleByKyc__NotEligible();
        }
        
        // step 5: call super
        return super.simulateLaw(initiator, lawCalldata, descriptionHash);
    }
}

contract DeployRoleByKyc is Law {
    error DeployRoleByKyc__AddressOccupied();
    error DeployRoleByKyc__RequestAmountExceedsAvailableFunds();

    LawConfig public configNewGrants; // config for new grants. 
    address public members;
    
    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_, // this is the configuration for creating new grants, not of the grants themselves. 
        address members_ // the address where account kyc are stored. - note: all on public blockchain..  
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        inputParams[0] = _dataType("string"); // name
        inputParams[1] = _dataType("string"); // description
        inputParams[2] = _dataType("uint32"); // role to be assigned
        inputParams[3] = _dataType("uint16[]"); // nationalities
        inputParams[4] = _dataType("uint16[]"); // countries of residence
        inputParams[5] = _dataType("int64"); // olderThan
        inputParams[6] = _dataType("int64"); // youngerThan
        
        members = members_;
        stateVars = inputParams; // Note: stateVars == inputParams.
      }
   
    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view 
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {   
        (
            string memory name, 
            string memory description, 
            uint32 role,
            uint16[] memory nationalities,
            uint16[] memory countryOfResidences, 
            int64 olderThan, // in seconds 
            int64 youngerThan // in seconds
            ) = abi.decode(lawCalldata, (
                string, string, uint32, uint16[], uint16[], int64, int64
                ));

        // step 0: calculate address at which grant will be created. 
        address contractAddress = _getContractAddress(name, description, role, nationalities, countryOfResidences, olderThan, youngerThan);

        // step 1: if address is already in use, revert.
        uint256 codeSize = contractAddress.code.length;
        if (codeSize > 0) {
            revert DeployRoleByKyc__AddressOccupied();
        }

        // step 3: create arrays
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // step 4: fill out arrays with data
        targets[0] = separatedPowers;
        calldatas[0] = abi.encodeWithSelector(SeparatedPowers.adoptLaw.selector, contractAddress);
        stateChange = lawCalldata;

        // step 5: return data
        return (targets, values, calldatas, stateChange);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {

        // step 0: decode data from stateChange
        (
            string memory name, 
            string memory description, 
            uint32 role,
            uint16[] memory nationalities,
            uint16[] memory countryOfResidences, 
            int64 olderThan, // in seconds 
            int64 youngerThan // in seconds
            ) = abi.decode(stateChange, (
                string, string, uint32, uint16[], uint16[], int64, int64
                ));

        // stp 1: deploy new grant
        _deployContract(name, description, role, nationalities, countryOfResidences, olderThan, youngerThan);      
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     * exact copy from SimpleAccountFactory.sol, except it takes loyaltyProgram as param
     */
    function _getContractAddress(
        string memory name, 
        string memory description, 
        uint32 roleId,
        uint16[] memory nationalities,
        uint16[] memory countryOfResidences, 
        int64 olderThan, // in seconds 
        int64 youngerThan // in seconds
        ) internal view returns (address) {
            Create2.computeAddress(bytes32(keccak256(abi.encodePacked(name, description))), keccak256(abi.encodePacked(
                type(RoleByKyc).creationCode,
                abi.encode(
                    // standard params
                    name,
                    description,
                    separatedPowers,
                    allowedRole,
                    configNewGrants,
                    // self select
                    roleId, 
                    // remaining params
                    nationalities,
                    countryOfResidences,
                    olderThan,
                    youngerThan,
                    members
                )
            )));
        }

    function _deployContract(
        string memory name, 
        string memory description, 
        uint32 roleId,
        uint16[] memory nationalities,
        uint16[] memory countryOfResidences, 
        int64 olderThan, // in seconds 
        int64 youngerThan // in seconds
        ) internal {
            RoleByKyc newFilter = new RoleByKyc{salt: bytes32(keccak256(abi.encodePacked(name, description)))}(
                // standard params
                name,
                description,
                separatedPowers,
                allowedRole,
                configNewGrants,
                // self select
                roleId,
                // remaining params
                nationalities,
                countryOfResidences,
                olderThan,
                youngerThan,
                members
            );
    }
}

// @title AiAgents
contract AiAgents is Law {
    error AiAgents__AgentAlreadyExists();
    error AiAgents__AgentDoesNotExist();

    struct AiAgent {
        string name;
        address account; 
        string uri;
    }
    AiAgent[] public aiAgentsList;
    uint256 public aiAgentsCount;
    
    event AiAgents__AgentAdded(address indexed account, string name, string uri);
    event AiAgents__AgentRemoved(address indexed account);

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        inputParams[0] = _dataType("string");  // name
        inputParams[1] = _dataType("address"); // account
        inputParams[2] = _dataType("string");  // uri
        inputParams[3] = _dataType("bool");   // add
      }
   
    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view 
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {   
        // step 0: decode law calldata
        (string memory name, address account, , bool add) = abi.decode(lawCalldata, (string, address, string, bool));
        
        // step 1: run additional checks 
        if (add) {
            for (uint256 i = 0; i < aiAgentsCount; i++) {
                if (aiAgentsList[i].account == account) {
                    revert AiAgents__AgentAlreadyExists();
                }
            }
        }

        if (!add) {
            bool agentFound;
            for (uint256 i = 0; i < aiAgentsCount; i++) {
                if (aiAgentsList[i].account == account) {
                    agentFound = true; 
                    break; 
                }
            }
            if (!agentFound) {
                revert AiAgents__AgentDoesNotExist();
            }
        }

        // step 2: create arrays 
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // step 3: fill out arrays with data - no action should be taken by protocol. 
        targets[0] = address(1);
        stateChange = lawCalldata; 

        // step 4: return data 
        return (targets, values, calldatas, stateChange);
    }

    // add or remove member from state mapping in law. 
    function _changeStateVariables(bytes memory stateChange) internal override {
        (string memory name, address account, string memory uri, bool add) = abi.decode(stateChange, (string, address, string, bool));

        if (add) {
            aiAgentsList.push(AiAgent(name, account, uri)); 
            aiAgentsCount++; 
            emit AiAgents__AgentAdded(account, name, uri);     
        } 
        
        if (!add) {
            for (uint256 i = 0; i < aiAgentsCount; i++) {
                if (aiAgentsList[i].account == account) {
                    aiAgentsList[i] = aiAgentsList[aiAgentsCount - 1];
                    aiAgentsList.pop(); 
                    aiAgentsCount--;
                    break;
                }
            }
            emit AiAgents__AgentRemoved(account);
        }
    }
}

contract DeployBespokeAction is Law {
    error DeployBespokeAction__AddressOccupied();
    error DeployBespokeAction__RequestAmountExceedsAvailableFunds();

    LawConfig public configNewBespokeAction; // config for new grants. 
    
    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_ // this is the configuration for creating new grants, not of the grants themselves. 
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {        
        inputParams[0] = _dataType("string"); // name
        inputParams[1] = _dataType("string"); // description
        inputParams[2] = _dataType("uint32"); // allowedRole
        inputParams[3] = _dataType("address"); // target contract
        inputParams[4] = _dataType("bytes4"); // target function 
        inputParams[5] = _dataType("string[]"); // params
        
        stateVars = inputParams; // Note: stateVars == inputParams.
      }
   
    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view 
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {   
        (
            string memory name, 
            string memory description, 
            uint32 allowedRole,
            address targetContract,
            bytes4  targetFunction,
            string[] memory params
            ) = abi.decode(lawCalldata, (
                string, string, uint32, address, bytes4, string[]
                )); 

        // step 0: calculate address at which grant will be created. 
        address contractAddress = _getContractAddress(name, description, allowedRole, targetContract, targetFunction, params);

        // step 1: if address is already in use, revert.
        uint256 codeSize = contractAddress.code.length;
        if (codeSize > 0) {
            revert DeployBespokeAction__AddressOccupied();
        }

        // step 3: create arrays
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // step 4: fill out arrays with data
        targets[0] = separatedPowers;
        calldatas[0] = abi.encodeWithSelector(SeparatedPowers.adoptLaw.selector, contractAddress);
        stateChange = lawCalldata;

        // step 5: return data
        return (targets, values, calldatas, stateChange);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {

        // step 0: decode data from stateChange
        (
            string memory name, 
            string memory description, 
            uint32 allowedRole,
            address targetContract,
            bytes4  targetFunction,
            string[] memory params
            ) = abi.decode(stateChange, (
                string, string, uint32, address, bytes4, string[]
                ));

        // stp 1: deploy new grant
        _deployContract(name, description, allowedRole, targetContract, targetFunction, params);   
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     * exact copy from SimpleAccountFactory.sol, except it takes loyaltyProgram as param
     */
    function _getContractAddress(
        string memory name, 
        string memory description, 
        uint32 allowedRole,
        address targetContract,
        bytes4  targetFunction,
        string[] memory params
        ) internal view returns (address) {
            Create2.computeAddress(bytes32(keccak256(abi.encodePacked(name, description))), keccak256(abi.encodePacked(
                type(BespokeAction).creationCode,
                abi.encode(
                    // standard params
                    name,
                    description,
                    separatedPowers,
                    allowedRole,
                    configNewBespokeAction,
                    // remaining params
                    targetContract,
                    targetFunction,
                    params
                )
            )));
        }

    function _deployContract(
        string memory name, 
        string memory description, 
        uint32 allowedRole,
        address targetContract,
        bytes4  targetFunction,
        string[] memory params
        ) internal {
            BespokeAction newBespokeAction = new BespokeAction{salt: bytes32(keccak256(abi.encodePacked(name, description)))}(
                // standard params
                name,
                description,
                separatedPowers,
                allowedRole,
                configNewBespokeAction,
                // remaining params
                targetContract,
                targetFunction,
                params
            );
    }
}
