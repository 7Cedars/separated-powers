// SPDX-License-Identifier: MIT

/// @notice Example DAO constitution for the SeparatedPowers example.
/// 
/// @dev The constitution uses four roles: PUBLIC_ROLE, DELEGATE_ROLE, SENIOR_ROLE, and ADMIN_ROLE.
/// - PUBLIC_ROLE: is anyone. 
/// - DELEGATE_ROLE: is selected on basis of delegated voting among token holders. 
/// - SENIOR_ROLE: is selected by peers holding SENIOR_ROLE.
/// - ADMIN_ROLE: is the admin of the DAO. Assigned at initiation.
/// See laws[0], laws[1] and laws[2] for the implementation of electing roles. PUBLIC_ROLE and ADMIN_ROLE are default roles, they are assigned at construction of the DAO. 
///
/// @dev The constitution uses three laws:
/// - laws[3]: Delegates can propose a new action to be executed by vote (two/third quorum, with simple majority FOR vote). This can be any action (including creating a new law.) They cannot implement it. 
/// - laws[4]: Seniors can execute actions that delegates proposed. By vote (50 percent quorum, with two/thirds majority FOR vote). 
/// - laws[5]: Admin can create a veto on an existing actions. 
///  
/// Note. IMPORTANT: This is a work in progress. Do not use in production. It does not come with any guarantees, warranties of any kind. 
/// 
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon
pragma solidity 0.8.26;

import { SeparatedPowers } from "../../../SeparatedPowers.sol";

// electoral laws
import { Law } from "../../../Law.sol";
import { ILaw } from "../../../interfaces/ILaw.sol";
import { TokensSelect } from "../../laws/electoral/TokensSelect.sol";
import { DirectSelect } from "../../laws/electoral/DirectSelect.sol";
import { DelegateSelect } from "../../laws/electoral/DelegateSelect.sol";
import { NominateMe } from "../../laws/electoral/NominateMe.sol";

// executive laws
import { ProposalOnly } from "../../laws/executive/ProposalOnly.sol";
import { OpenAction } from "../../laws/executive/OpenAction.sol";

contract Constitution {
    uint32 constant NUMBER_OF_LAWS = 6;

    function initiate(address payable dao_, address payable mockErc20Votes_)
        external
        returns (
            address[] memory laws,
            uint32[] memory allowedRoles,
            ILaw.LawConfig[] memory lawConfigs
        )
    {
        laws = new address[](NUMBER_OF_LAWS);
        allowedRoles = new uint32[](NUMBER_OF_LAWS);
        lawConfigs = new ILaw.LawConfig[](NUMBER_OF_LAWS);
    
    //////////////////////////////////////////////////////////////
    //              CHAPTER 1: ELECT ROLES                      //
    //////////////////////////////////////////////////////////////
    laws[0] = address(
        new NominateMe(
            "Nominees for DELEGATE_ROLE", // max 31 chars
            "Anyone can nominate themselves for a WHALE_ROLE",
            dao_
        )
    );
    allowedRoles[1] = type(uint32).max;

    laws[1] = address(
        new DelegateSelect(
            "Anyone can elect delegates", // max 31 chars
            "Anyone can call (and pay for) a delegate election at any time. The nominated accounts with most delegated vote tokens will be assigned the DELEGATE_ROLE.",
            dao_, // separated powers protocol. 
            mockErc20Votes_, // the tokens that will be used as votes in the election. 
            laws[0], // nominateMe 
            25,
            2
        )
    );
    allowedRoles[1] = SeparatedPowers(dao_).PUBLIC_ROLE(); // anyone can call for an election at any time. 

    laws[2] = address(
        new DirectSelect(
            "Seniors elect seniors", // max 31 chars
            "Seniors can propose and vote to (de)select an account for the SENIOR_ROLE.",
            dao_,
            1
        )
    ); 
    allowedRoles[2] = 1; 
    lawConfigs[2].quorum = 20; // = Only 20% quorum needed
    lawConfigs[2].succeedAt = 66; // = but at least 2/3 majority needed for assigning and revoking members.
    lawConfigs[2].votingPeriod = 1200; // = number of blocks
    // note: there is no maximum or minimum number of seniors. But at least one senior NEEDS TO BE ELECTED THROUGH CONSTITUTION OF THE DAO. Otherwise it will never be possible to elect seniors.   

    //////////////////////////////////////////////////////////////
    //              CHAPTER 2: EXECUTIVE ACTIONS                //
    //////////////////////////////////////////////////////////////
    
    // note: no guardrails on the parameters of the action. Anything can be proposed. 
    bytes4[] memory paramsAction = new bytes4[](3);
    paramsAction[0] = bytes4(keccak256("address[]")); // targets 
    paramsAction[1] = bytes4(keccak256("uint256[]")); // values
    paramsAction[2] = bytes4(keccak256("bytes[]")); // calldatas

    laws[3] = address(
        new ProposalOnly(
            "Delegates propose actions", 
            "Delegates can propose new actions to be executed. They cannot implement it.", 
            dao_, 
            paramsAction
        )
    );
    allowedRoles[3] = 2; 
    lawConfigs[3].quorum = 66; // = Two thirds quorum needed to pass the proposal
    lawConfigs[3].succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
    lawConfigs[3].votingPeriod = 50400; // = duration in number of blocks to vote, about one week. 

    laws[4] = address(
        new OpenAction(
            "Seniors execute actions",
            "Seniors can execute actions that delegates proposed. By vote. Admin can veto any execution.",
            dao_ // separated powers
        )
    );
    allowedRoles[4] = 1; 
    lawConfigs[4].quorum = 51; // = 51 majority of seniors need to vote. 
    lawConfigs[4].succeedAt = 66; // =  two/thirds majority FOR vote needed to pass. 
    lawConfigs[4].votingPeriod = 50400; // = duration in number of blocks to vote, about one week. 
    lawConfigs[4].needCompleted = laws[3]; // needs the proposal by Delegates to be completed.
    lawConfigs[4].delayExecution = 25200; // = duration in number of blocks (= half a week).
    lawConfigs[4].needNotCompleted = laws[5]; // needs the admin NOT to have cast a veto.  

    laws[5] = address(
        new ProposalOnly(
            "Admin can veto actions", 
            "An admin can veto any action. No vote as only one address holds the ADMIN_ROLE.", 
            dao_, 
            paramsAction
        )
    );
    allowedRoles[5] = SeparatedPowers(dao_).ADMIN_ROLE(); 
    }
}
