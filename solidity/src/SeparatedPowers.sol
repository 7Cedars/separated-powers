// SPDX-License-Identifier: MIT

/// @title Separated Powers Protocol v.0.2  
/// @notice Separated Powers is a Role Restricted Governance Protocol. It provides a flexible, decentralised, efficient and secure governance framework for DAOs.
/// 
/// @dev This contract is the core protocol. It is meant to be used in combination with implementations of {Law.sol}. 
/// @dev Code is derived from OpenZeppelin's Governor.sol and AccessManager contracts, in addition to Haberdasher Labs Hats protocol.
/// @dev The protocol mirrors Governor.sol and AccessManager as closely as possible. It will, eventually, also be compatible with the Hats protocol. 
///
/// Note several key differences from openzeppelin's {Governor.sol}.  
/// 1 - Any DAO action needs to be encoded in role restricted external contracts, or laws, that follow the {ILaw} interface.
/// 2 - Proposing, voting, cancelling and executing actions are role restricted along the target law that is called.
/// 3 - All DAO actions need to run through the governance protocol. Calls to laws that do not need a proposal vote to be executed, still need to be executed through the {execute} function of the core protocol.
/// 4 - The core protocol uses a non-weighted voting mechanism: one account has one vote.
/// 5 - The core protocol is minimalistic. Any complexity (timelock, delayed execution, guardian roles, weighted votes, staking, etc.) has to be integrated through laws.
///
/// For example implementations of DAOs, see the implementations/daos folder.
/// 
/// Note This protocol is a work in progress. A number of features are planned to be added in the future.
/// - Support for {clock} for timestamping of proposals.
/// - Full compatibility with {Governor.sol} will be implemented, so the protocol can be used in combination websites such as Tally.xyz.  
/// - Integration of, or support for, the Hats Protocol.
/// - Testing and example implementations are still incomplete. 
///
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon

pragma solidity 0.8.26;

import { Law } from "./Law.sol";
import { ILaw } from "./interfaces/ILaw.sol";
import { ISeparatedPowers } from "./interfaces/ISeparatedPowers.sol";
import { ERC165Checker } from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import { Address } from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import { EIP712 } from "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

// £NB ONLY FOR TESTING DO NOT USE IN PRODUCTION
import { console } from "lib/forge-std/src/console.sol";

contract SeparatedPowers is EIP712, ISeparatedPowers {
    //////////////////////////////////////////////////////////////
    //                           STORAGE                        //
    /////////////////////////////////////////////////////////////
    mapping(uint256 actionId => Proposal) private _proposals; // mapping from actionId to proposal
    mapping(address lawAddress => LawConfig) public laws;
    mapping(uint32 roleId => Role) public roles;

    // two roles are preset: ADMIN_ROLE == 0 and PUBLIC_ROLE == type(uint48).max.
    uint32 public constant ADMIN_ROLE = type(uint32).min; // == 0
    uint32 public constant PUBLIC_ROLE = type(uint32).max; // == a lot
    uint256 constant DENOMINATOR = 100; // = 100%

    string public name; // name of the DAO.
    bool private _constituentLawsExecuted; // has the constitute function been called before?

    //////////////////////////////////////////////////////////////
    //                          MODIFIERS                       //
    //////////////////////////////////////////////////////////////
    /// @notice A modifier that sets a function to only be callable by the {SeparatedPowers} contract.
    modifier onlySeparatedPowers() {
        if (msg.sender != address(this)) {
            revert SeparatedPowers__OnlySeparatedPowers();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //              CONSTRUCTOR & RECEIVE                       //
    //////////////////////////////////////////////////////////////
    /// @notice  Sets the value for {name} at the time of construction.
    ///
    /// @param name_ name of the contract
    constructor(string memory name_) EIP712(name_, version()) {
        name = name_;
        _setRole(ADMIN_ROLE, msg.sender, true); // the account that initiates a SeparatedPowers contract is set to its admin.

        roles[ADMIN_ROLE].amountMembers = 1; // the number of admins at set up is 1.
        roles[PUBLIC_ROLE].amountMembers = type(uint256).max; // the number for holders of the PUBLIC_ROLE is type(uint256).max. As in, everyone has this role.

        emit SeparatedPowers__Initialized(address(this));
    }

    /// @notice receive function enabling ETH deposits.
    ///
    /// @dev This is a virtual function, and can be overridden in the DAO implementation.
    /// @dev No access control on this function: anyone can send funds into the main contract.
    receive() external payable virtual {
        emit FundsReceived(msg.value);
    }

    //////////////////////////////////////////////////////////////
    //                  GOVERNANCE LOGIC                        //
    //////////////////////////////////////////////////////////////
    /// @inheritdoc ISeparatedPowers
    function propose(address targetLaw, bytes memory lawCalldata, string memory description)
        external
        virtual
        returns (uint256)
    {
        // check 1: does msg.sender have access to targetLaw?
        uint32 allowedRole = laws[targetLaw].allowedRole;
        if (roles[allowedRole].members[msg.sender] == 0 && allowedRole != PUBLIC_ROLE) {
            revert SeparatedPowers__AccessDenied();
        }
        // check 2: is targetLaw is an active law?
        if (!laws[targetLaw].active) {
            revert SeparatedPowers__NotActiveLaw();
        }
        // check 3: does target law need proposal vote to pass?
        if (laws[targetLaw].quorum == 0) {
            revert SeparatedPowers__NoVoteNeeded();
        }

        // if check passes: propose.
        return _propose(msg.sender, targetLaw, lawCalldata, description);
    }

    /// @notice Internal propose mechanism. Can be overridden to add more logic on proposal creation.
    ///
    /// @dev The mechanism checks for the length of targets and calldatas.
    ///
    /// Emits a {SeperatedPowersEvents::ProposalCreated} event.
    function _propose(address initiator, address targetLaw, bytes memory lawCalldata, string memory description)
        internal
        virtual
        returns (uint256 actionId)
    {
        actionId = hashProposal(targetLaw, lawCalldata, keccak256(bytes(description)));
        if (_proposals[actionId].voteStart != 0) {
            revert SeparatedPowers__UnexpectedActionState();
        }

        uint32 duration = laws[targetLaw].votingPeriod;
        Proposal storage proposal = _proposals[actionId];
        proposal.targetLaw = targetLaw;
        proposal.voteStart = uint48(block.number); // note that the moment proposal is made, voting start. There is no delay functionality.
        proposal.voteDuration = duration;
        proposal.initiator = initiator;

        emit ProposalCreated(
            actionId, initiator, targetLaw, "", lawCalldata, block.number, block.number + duration, description
        );
    }

    /// @inheritdoc ISeparatedPowers
    function cancel(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        virtual
        returns (uint256)
    {
        uint256 actionId = hashProposal(targetLaw, lawCalldata, descriptionHash);
        // only initiator can cancel a proposal
        if (msg.sender != _proposals[actionId].initiator) {
            revert SeparatedPowers__AccessDenied();
        }

        return _cancel(targetLaw, lawCalldata, descriptionHash);
    }

    /// @notice Internal cancel mechanism with minimal restrictions. A proposal can be cancelled in any state other than
    /// Cancelled or Executed. Once cancelled a proposal cannot be re-submitted.
    ///
    /// @dev the account to cancel must be the account that created the proposal.
    /// Emits a {SeperatedPowersEvents::ProposalCanceled} event.
    function _cancel(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        internal
        virtual
        returns (uint256)
    {
        uint256 actionId = hashProposal(targetLaw, lawCalldata, descriptionHash);

        if (_proposals[actionId].targetLaw == address(0)) {
            revert SeparatedPowers__InvalidProposalId();
        }
        if (_proposals[actionId].completed || _proposals[actionId].cancelled) {
            revert SeparatedPowers__UnexpectedActionState();
        }

        _proposals[actionId].cancelled = true;
        emit ProposalCancelled(actionId);

        return actionId;
    }

    /// @inheritdoc ISeparatedPowers
    function castVote(uint256 actionId, uint8 support) external virtual {
        address voter = msg.sender;
        return _castVote(actionId, voter, support, "");
    }

    /// @inheritdoc ISeparatedPowers
    function castVoteWithReason(uint256 actionId, uint8 support, string calldata reason) public virtual {
        address voter = msg.sender;
        return _castVote(actionId, voter, support, reason);
    }

    /// @notice Internal vote casting mechanism.
    /// Check that the proposal is active, and that account is has access to targetLaw.
    ///
    /// Emits a {SeperatedPowersEvents::VoteCast} event.
    function _castVote(uint256 actionId, address account, uint8 support, string memory reason) internal virtual {
        // Check that the proposal is active, that it has not been paused, cancelled or ended yet.
        if (SeparatedPowers(payable(address(this))).state(actionId) != ActionState.Active) {
            revert SeparatedPowers__ProposalNotActive();
        }
        // Note that we check if account has access to the law targetted in the proposal.
        address targetLaw = _proposals[actionId].targetLaw;
        uint32 allowedRole = laws[targetLaw].allowedRole;
        if (roles[allowedRole].members[account] == 0 && allowedRole != PUBLIC_ROLE) {
            revert SeparatedPowers__AccessDenied();
        }
        // if all this passes: cast vote.
        _countVote(actionId, account, support);

        emit VoteCast(account, actionId, support, reason);
    }

    /// @inheritdoc ISeparatedPowers
    function execute(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash) external payable virtual {
        uint256 actionId = hashProposal(targetLaw, lawCalldata, descriptionHash);
        // check 1: does executioner have access to law being executed?
        uint32 allowedRole = laws[targetLaw].allowedRole;
        if (roles[allowedRole].members[msg.sender] == 0 && allowedRole != PUBLIC_ROLE) {
            revert SeparatedPowers__AccessDenied();
        }
        // check 2: is targetLaw is an active law?
        if (!laws[targetLaw].active) {
            revert SeparatedPowers__NotActiveLaw();
        }
        // check 3: has action already been set as completed?
        if (_proposals[actionId].completed == true) {
            revert SeparatedPowers__ProposalAlreadyCompleted();
        }
        // check 4: is proposal cancelled?
        // if law did not need a proposal proposal vote to start with, check will pass.
        if (_proposals[actionId].cancelled == true) {
            revert SeparatedPowers__ProposalCancelled();
        }

        // if checks pass, call target law -> receive targets, values and calldatas
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) =
            Law(targetLaw).executeLaw(msg.sender, lawCalldata, descriptionHash);
        // check return data law.
        if (targets.length == 0 || targets[0] == targetLaw || targets[0] == address(0)) {
            revert SeparatedPowers__LawDidNotPassChecks();
        }

        // If checks passed, set proposal as completed and emit event.
        _proposals[actionId].initiator = msg.sender; // note if initiator had been set during proposal, it will be overwritten.
        _proposals[actionId].completed = true;
        emit ProposalCompleted(msg.sender, targetLaw, lawCalldata, descriptionHash);

        // if targets[0] == address(1) nothing should be executed.
        if (targets[0] == address(1)) {
            return;
        }

        // otherwise: execute targets[], values[], calldatas[] received from law.
        _executeOperations(targets, values, calldatas);
    }

    /// @notice Internal execution mechanism.
    /// Can be overridden (without a super call) to modify the way execution is performed
    ///
    /// NOTE: Calling this function directly will NOT check the current state of the proposal, set the executed flag to
    /// true or emit the `ProposalExecuted` event. Executing a proposal should be done using {execute}.
    function _executeOperations(address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
        internal
        virtual
    {
        if (targets.length != values.length || targets.length != calldatas.length) {
            revert SeparatedPowers__InvalidCallData();
        }
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{ value: values[i] }(calldatas[i]);
            Address.verifyCallResult(success, returndata);
        }
        emit ProposalExecuted(targets, values, calldatas);
    }

    //////////////////////////////////////////////////////////////
    //                  ROLE AND LAW ADMIN                      //
    //////////////////////////////////////////////////////////////
    /// @inheritdoc ISeparatedPowers
    function constitute(
        // laws data
        address[] memory constituentLaws,
        uint32[] memory allowedRoles,
        uint8[] memory quorums,
        uint8[] memory succeedAts,
        uint32[] memory votingPeriods,
        // roles data
        uint32[] memory constituentRoles,
        address[] memory constituentAccounts
    ) external virtual {
        // check 1: only admin can call this function
        if (roles[ADMIN_ROLE].members[msg.sender] == 0) {
            revert SeparatedPowers__AccessDenied();
        }

        // check 2: check lengths of arrays
        if (
            constituentLaws.length != allowedRoles.length || constituentLaws.length != quorums.length
                || constituentLaws.length != succeedAts.length || constituentLaws.length != votingPeriods.length
                || constituentRoles.length != constituentAccounts.length
        ) {
            revert SeparatedPowers__InvalidArrayLengths();
        }

        // check 3: this function can only be called once.
        if (_constituentLawsExecuted) {
            revert SeparatedPowers__ConstitutionAlreadyExecuted();
        }

        // if checks pass, set _constituentLawsExecuted to true...
        _constituentLawsExecuted = true;

        // ...set laws
        for (uint256 i = 0; i < constituentLaws.length; i++) {
            _setLaw(constituentLaws[i], allowedRoles[i], quorums[i], succeedAts[i], votingPeriods[i]);
        }
        // ...and set roles
        for (uint256 i = 0; i < constituentRoles.length; i++) {
            _setRole(constituentRoles[i], constituentAccounts[i], true);
        }
    }

    /// @inheritdoc ISeparatedPowers
    function setLaw(address law, uint32 allowedRole, uint8 quorum, uint8 succeedAt, uint32 votingPeriod)
        public
        onlySeparatedPowers
    {
        _setLaw(law, allowedRole, quorum, succeedAt, votingPeriod);
    }

    /// @inheritdoc ISeparatedPowers
    function revokeLaw(address law) public onlySeparatedPowers {
        if (!laws[law].active) {
            revert SeparatedPowers__LawNotActive();
        }

        emit LawRevoked(law);
        laws[law].active = false;
    }

    /// @notice internal function to set a law or revoke it.
    ///
    /// @param law address of the law.
    /// @param allowedRole : the allowed role of the law.
    /// @param quorum : the quorum of the law.
    /// @param succeedAt : the succeedAt of the law.
    /// @param votingPeriod : the votingPeriod of the law.
    ///
    /// Emits a {SeperatedPowersEvents::LawSet} event.
    function _setLaw(address law, uint32 allowedRole, uint8 quorum, uint8 succeedAt, uint32 votingPeriod)
        internal
        virtual
    {
        // check if added address is indeed a law
        if (!ERC165Checker.supportsInterface(law, type(ILaw).interfaceId)) {
            revert SeparatedPowers__IncorrectInterface();
        }

        bool existingLaw = (laws[law].active);

        laws[law] = LawConfig({
            lawAddress: law,
            allowedRole: allowedRole,
            quorum: quorum,
            succeedAt: succeedAt,
            votingPeriod: votingPeriod,
            active: true
        });

        emit LawSet(law, allowedRole, existingLaw, quorum, succeedAt, votingPeriod);
    }

    /// @inheritdoc ISeparatedPowers
    function setRole(uint32 roleId, address account, bool access) public virtual onlySeparatedPowers {
        _setRole(roleId, account, access);
    }

    /// @notice Internal version of {setRole} without access control.
    ///
    /// Emits a {SeperatedPowersEvents::RolSet} event.
    function _setRole(uint32 roleId, address account, bool access) internal virtual {
        bool newMember = roles[roleId].members[account] == 0;

        if (access && newMember) {
            roles[roleId].members[account] = uint48(block.number); // 'since' is set at current block.number
            roles[roleId].amountMembers++;
        } else if (!access && !newMember) {
            roles[roleId].members[account] = 0;
            roles[roleId].amountMembers--;
        } else {
            revert SeparatedPowers__RoleAccessNotChanged();
        }
        emit RoleSet(roleId, account);
    }

    //////////////////////////////////////////////////////////////
    //                     HELPER FUNCTIONS                     //
    //////////////////////////////////////////////////////////////
    /// @notice internal function {quorumReached} that checks if the quorum for a given proposal has been reached.
    ///
    /// @param actionId id of the proposal.
    /// @param targetLaw address of the law that the proposal belongs to.
    ///
    function _quorumReached(uint256 actionId, address targetLaw) internal view virtual returns (bool) {
        Proposal storage proposal = _proposals[actionId];

        uint8 quorum = laws[targetLaw].quorum;
        uint32 allowedRole = laws[targetLaw].allowedRole;
        uint256 amountMembers = roles[allowedRole].amountMembers;

        return (
            quorum == 0
                || (amountMembers * quorum) / DENOMINATOR <= proposal.forVotes + proposal.abstainVotes
        );
    }

    /// @notice internal function {voteSucceeded} that checks if a vote for a given proposal has succeeded.
    ///
    /// @param actionId id of the proposal.
    /// @param targetLaw address of the law that the proposal belongs to.
    function _voteSucceeded(uint256 actionId, address targetLaw) internal view virtual returns (bool) {
        Proposal storage proposal = _proposals[actionId];

        uint8 succeedAt = laws[targetLaw].succeedAt;
        uint8 quorum = laws[targetLaw].quorum;
        uint32 allowedRole = laws[targetLaw].allowedRole;
        uint256 amountMembers = roles[allowedRole].amountMembers;

        // note if quorum is set to 0 in a Law, it will automatically return true.
        return quorum == 0 || amountMembers * succeedAt <= proposal.forVotes * DENOMINATOR;
    }

    /// @notice internal function {countVote} that counts against, for, and abstain votes for a given proposal.
    ///
    /// @dev In this module, the support follows the `VoteType` enum (from Governor Bravo).
    /// @dev It does not check if account has roleId referenced in actionId. This has to be done by {SeparatedPowers.castVote} function.
    function _countVote(uint256 actionId, address account, uint8 support) internal virtual {
        Proposal storage proposal = _proposals[actionId];

        if (proposal.hasVoted[account]) {
            revert SeparatedPowers__AlreadyCastVote();
        }
        proposal.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposal.againstVotes++;
        } else if (support == uint8(VoteType.For)) {
            proposal.forVotes++;
        } else if (support == uint8(VoteType.Abstain)) {
            proposal.abstainVotes++;
        } else {
            revert SeparatedPowers__InvalidVoteType();
        }
    }

    /// @inheritdoc ISeparatedPowers
    function hashProposal(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        pure
        virtual
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(targetLaw, lawCalldata, descriptionHash)));
    }

    //////////////////////////////////////////////////////////////
    //                      VIEW FUNCTIONS                      //
    //////////////////////////////////////////////////////////////
    /// @inheritdoc ISeparatedPowers
    function state(uint256 actionId) public view virtual returns (ActionState) {
        // We read the struct fields into the stack at once so Solidity emits a single SLOAD
        Proposal storage proposal = _proposals[actionId];
        bool proposalCompleted = proposal.completed;
        bool proposalCancelled = proposal.cancelled;

        if (proposalCompleted) {
            return ActionState.Completed;
        }
        if (proposalCancelled) {
            return ActionState.Cancelled;
        }

        uint256 start = _proposals[actionId].voteStart; // = startDate

        if (start == 0) {
            revert SeparatedPowers__InvalidProposalId();
        }

        uint256 deadline = proposalDeadline(actionId);
        address targetLaw = proposal.targetLaw;

        if (deadline >= block.number) {
            return ActionState.Active;
        } else if (!_quorumReached(actionId, targetLaw) || !_voteSucceeded(actionId, targetLaw)) {
            return ActionState.Defeated;
        } else {
            return ActionState.Succeeded;
        }
    }

    /// @notice saves the version of the SeparatedPowers implementation.
    function version() public pure returns (string memory) {
        return "1";
    }

    /// @notice public function {SeparatedPowers::canCallLaw} that checks if a caller can call a given law.
    ///
    /// @param caller address of the caller.
    /// @param targetLaw address of the law to check.
    function canCallLaw(address caller, address targetLaw) public view returns (bool) {
        uint32 allowedRole = laws[targetLaw].allowedRole;
        uint48 since = hasRoleSince(caller, allowedRole);

        return since != 0;
    }

    /// @inheritdoc ISeparatedPowers
    function hasRoleSince(address account, uint32 roleId) public view returns (uint48 since) {
        return roles[roleId].members[account];
    }

    /// @inheritdoc ISeparatedPowers
    function hasVoted(uint256 actionId, address account) public view virtual returns (bool) {
        return _proposals[actionId].hasVoted[account];
    }

    /// @inheritdoc ISeparatedPowers
    function getProposalVotes(uint256 actionId)
        public
        view
        virtual
        returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes)
    {
        Proposal storage proposal = _proposals[actionId];
        return (proposal.againstVotes, proposal.forVotes, proposal.abstainVotes);
    }

    /// @inheritdoc ISeparatedPowers
    function getInitiatorAction(uint256 actionId) public view virtual returns (address initiator) {
        return _proposals[actionId].initiator;
    }

    /// @inheritdoc ISeparatedPowers
    function getAmountRoleHolders(uint32 roleId) public view returns (uint256 amountMembers) {
        return roles[roleId].amountMembers;
    }

    /// @inheritdoc ISeparatedPowers
    function proposalDeadline(uint256 actionId) public view virtual returns (uint256) {
        // uint48 + uint32 => uint256. £test if this works properly.
        return _proposals[actionId].voteStart + _proposals[actionId].voteDuration;
    }

    /// @inheritdoc ISeparatedPowers
    function getActiveLaw(address law) external view returns (bool active) {
        return laws[law].active;
    }

    //////////////////////////////////////////////////////////////
    //                       COMPLIENCE                         //
    //////////////////////////////////////////////////////////////
    /// @notice implements ERC721Receiver
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice implements ERC1155Receiver
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @notice implements ERC1155BatchReceiver
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        virtual
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
