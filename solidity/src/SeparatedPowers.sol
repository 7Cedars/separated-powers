// SPDX-License-Identifier: MIT

/// @notice The core contract of the SeparatedPowers protocol. Inherits from {ISeparatedPowers}.
/// Code derived from OpenZeppelin's Governor.sol contract.
///
/// @dev Inoriginally, Governor.sol is abstract and needs modules to be added to function.
/// In contrast, SeparatedPowers is not set as abstract and is self-contained.
/// Any additional functionality is added through laws.
/// Although the protocol does allow functions to be updated in inhereted contracts, this should be avoided if possible.
///
/// The protocol is meant to be inherited by a contract that implements a DAO. See for example ./implementations.
///
/// Other differences:
/// - No ERC165 in the core protocol, this can change later. Laws do support ERC165 interfaces.
/// - The use of {clock} is removed. Only blocknumbers are used at the moment, no timestamps. This also applies to laws.
///
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon

pragma solidity 0.8.26;

import { Law } from "./Law.sol";
import { ILaw } from "./interfaces/ILaw.sol";
import { ISeparatedPowers } from "./interfaces/ISeparatedPowers.sol";
import { ERC165Checker } from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import { Address } from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import { EIP712 } from "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

contract SeparatedPowers is EIP712, ISeparatedPowers {
    //////////////////////////////////////////////////////////////
    //                           STORAGE                        //
    /////////////////////////////////////////////////////////////
    mapping(uint256 actionId => ExecutiveAction) private _executiveActions; // mapping from actionId to executiveAction
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
        bytes32 descriptionHash = keccak256(bytes(description));
        (,, bytes32[] memory calldatas) = Law(targetLaw).executeLaw(msg.sender, lawCalldata, descriptionHash);
        if (calldatas[0].toString() != "proposal not succeeded") {
            revert SeparatedPowers__LawDoesNotNeedProposalVote();
        }

        // if check passes: propose.
        return _propose(msg.sender, targetLaw, lawCalldata, description);
    }

    /// @notice Internal propose mechanism. Can be overridden to add more logic on proposal creation.
    ///
    /// @dev The mechanism checks for access of initiator and for the length of targets and calldatas.
    ///
    /// Emits a {SeperatedPowersEvents::ExecutiveActionCreated} event.
    function _propose(address initiator, address targetLaw, bytes memory lawCalldata, string memory description)
        internal
        virtual
        returns (uint256 actionId)
    {
        // note that targetLaw AND initiator are hashed into the actionId. By including initiator in the hash, front running a proposal is made impossible.
        actionId = hashExecutiveAction(initiator, targetLaw, lawCalldata, keccak256(bytes(description)));
        if (_executiveActions[actionId].voteStart == 0) {
            revert SeparatedPowers__UnexpectedActionState();
        }

        uint32 duration = laws[targetLaw].votingPeriod;
        ExecutiveAction storage executiveAction = _executiveActions[actionId];
        executiveAction.targetLaw = targetLaw;
        executiveAction.voteStart = uint48(block.number); // note that the moment proposal is made, voting start. There is no delay functionality.
        executiveAction.voteDuration = duration;
        executiveAction.initiator = initiator;

        emit ExecutiveActionCreated(
            actionId, initiator, targetLaw, "", lawCalldata, block.number, block.number + duration, description
        );
    }

    /// @inheritdoc ISeparatedPowers
    function cancel(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        virtual
        returns (uint256)
    {
        uint256 actionId = hashExecutiveAction(msg.sender, targetLaw, lawCalldata, descriptionHash);
        // only initiator can cancel a proposal
        if (msg.sender != _executiveActions[actionId].initiator) {
            revert SeparatedPowers__AccessDenied();
        }

        return _cancel(targetLaw, lawCalldata, descriptionHash);
    }

    /// @notice Internal cancel mechanism with minimal restrictions. A executiveAction can be cancelled in any state other than
    /// Cancelled or Executed. Once cancelled a executiveAction cannot be re-submitted.
    ///
    /// @dev the account to cancel must be the account that created the executiveAction.
    /// Emits a {SeperatedPowersEvents::ExecutiveActionCanceled} event.
    function _cancel(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        internal
        virtual
        returns (uint256)
    {
        uint256 actionId = hashExecutiveAction(msg.sender, targetLaw, lawCalldata, descriptionHash);
        
        if (_executiveActions[actionId].targetLaw == address(0)) {
            revert SeparatedPowers__InvalidExecutiveActionId();
        }
        if (_executiveActions[actionId].completed || _executiveActions[actionId].cancelled) {
            revert SeparatedPowers__UnexpectedActionState();
        }

        _executiveActions[actionId].cancelled = true;
        emit ExecutiveActionCancelled(actionId);

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
    /// Check that the executiveAction is active, and that account is has access to targetLaw.
    ///
    /// Emits a {SeperatedPowersEvents::VoteCast} event.
    function _castVote(uint256 actionId, address account, uint8 support, string memory reason) internal virtual {
        // Check that the executiveAction is active, that it has not been paused, cancelled or ended yet.
        if (SeparatedPowers(payable(address(this))).state(actionId) != ActionState.Active) {
            revert SeparatedPowers__ExecutiveActionNotActive();
        }
        // Note that we check if account has access to the law targetted in the executiveAction.
        address targetLaw = _executiveActions[actionId].targetLaw;
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
        uint256 actionId = hashExecutiveAction(msg.sender, targetLaw, lawCalldata, descriptionHash);
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
        if (_executiveActions[actionId].completed == true) {
            revert SeparatedPowers__ExecutiveActionAlreadyCompleted();
        }
        // check 4: is executiveAction cancelled?
        // if law did not need a executiveAction vote, check will pass. 
        if (_executiveActions[actionId].cancelled == true) {
            revert SeparatedPowers__ExecutiveActionCancelled();
        }

        // if checks pass: calling target law and receiving targets, values and calldatas.
        // Note this call should never revert. It should always receive data from law.
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) =
            Law(targetLaw).executeLaw(msg.sender, lawCalldata, descriptionHash);

        // check return data from law.
        if (targets.length == 0 || targets[0] == targetLaw || targets[0] == address(0)) {
            revert SeparatedPowers__LawDidNotPassChecks();
        }
        // If checks passed, execute.
        _executiveActions[actionId].completed = true;
        emit ExecutiveActionCompleted(actionId);

        // a targets[0] == address(1) is a signal from a law to indicate that no action should be executed. 
        if (targets[0] == address(1)) {
            break; 
        }
        _executeOperations(targets, values, calldatas);
    }

    /// @notice Internal execution mechanism.
    /// Can be overridden (without a super call) to modify the way execution is performed
    ///
    /// NOTE: Calling this function directly will NOT check the current state of the executiveAction, set the executed flag to
    /// true or emit the `ExecutiveActionExecuted` event. Executing a executiveAction should be done using {execute}.
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
        emit ExecutiveActionExecuted(targets, values, calldatas);
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
            revert SeparatedPowers__IncorrectInterface(law);
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
    /// @notice internal function {quorumReached} that checks if the quorum for a given executiveAction has been reached.
    ///
    /// @param actionId id of the executiveAction.
    /// @param targetLaw address of the law that the executiveAction belongs to.
    ///
    function _quorumReached(uint256 actionId, address targetLaw) internal view virtual returns (bool) {
        ExecutiveAction storage executiveAction = _executiveActions[actionId];

        uint8 quorum = laws[targetLaw].quorum;
        uint32 allowedRole = laws[targetLaw].allowedRole;
        uint256 amountMembers = roles[allowedRole].amountMembers;

        return (quorum == 0 || (amountMembers * quorum) / DENOMINATOR <= executiveAction.forVotes + executiveAction.abstainVotes);
    }

    /// @notice internal function {voteSucceeded} that checks if a vote for a given executiveAction has succeeded.
    ///
    /// @param actionId id of the executiveAction.
    /// @param targetLaw address of the law that the executiveAction belongs to.
    function _voteSucceeded(uint256 actionId, address targetLaw) internal view virtual returns (bool) {
        ExecutiveAction storage executiveAction = _executiveActions[actionId];

        uint8 succeedAt = laws[targetLaw].succeedAt;
        uint8 quorum = laws[targetLaw].quorum;
        uint32 allowedRole = laws[targetLaw].allowedRole;
        uint256 amountMembers = roles[allowedRole].amountMembers;

        // note if quorum is set to 0 in a Law, it will automatically return true.
        return quorum == 0 || amountMembers * succeedAt <= executiveAction.forVotes * DENOMINATOR;
    }

    /// @notice internal function {countVote} that counts against, for, and abstain votes for a given executiveAction.
    ///
    /// @dev In this module, the support follows the `VoteType` enum (from Governor Bravo).
    /// @dev It does not check if account has roleId referenced in actionId. This has to be done by {SeparatedPowers.castVote} function.
    function _countVote(uint256 actionId, address account, uint8 support) internal virtual {
        ExecutiveAction storage executiveAction = _executiveActions[actionId];

        if (executiveAction.hasVoted[account]) {
            revert SeparatedPowers__AlreadyCastVote(account);
        }
        executiveAction.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            executiveAction.againstVotes++;
        } else if (support == uint8(VoteType.For)) {
            executiveAction.forVotes++;
        } else if (support == uint8(VoteType.Abstain)) {
            executiveAction.abstainVotes++;
        } else {
            revert SeparatedPowers__InvalidVoteType();
        }
    }

    /// @inheritdoc ISeparatedPowers
    function hashExecutiveAction(address initiator, address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        pure
        virtual
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(initiator, targetLaw, lawCalldata, descriptionHash)));
    }

    //////////////////////////////////////////////////////////////
    //                      VIEW FUNCTIONS                      //
    //////////////////////////////////////////////////////////////
    /// @inheritdoc ISeparatedPowers
    function state(uint256 actionId) public view virtual returns (ActionState) {
        // We read the struct fields into the stack at once so Solidity emits a single SLOAD
        ExecutiveAction storage executiveAction = _executiveActions[actionId];
        bool executiveActionCompleted = executiveAction.completed;
        bool executiveActionCancelled = executiveAction.cancelled;

        if (executiveActionCompleted) {
            return ActionState.Completed;
        }
        if (executiveActionCancelled) {
            return ActionState.Cancelled;
        }

        uint256 start = _executiveActions[actionId].voteStart; // = startDate

        if (start == 0) {
            revert SeparatedPowers__InvalidExecutiveActionId();
        }

        uint256 deadline = executiveActionDeadline(actionId);
        address targetLaw = executiveAction.targetLaw;

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
    function hasVoted(uint256 actionId, address account) public view virtual returns (bool) {
        return _executiveActions[actionId].hasVoted[account];
    }

    /// @inheritdoc ISeparatedPowers
    function executiveActionVotes(uint256 actionId)
        public
        view
        virtual
        returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes)
    {
        ExecutiveAction storage executiveAction = _executiveActions[actionId];
        return (executiveAction.againstVotes, executiveAction.forVotes, executiveAction.abstainVotes);
    }

    /// @inheritdoc ISeparatedPowers
    function hasRoleSince(address account, uint32 roleId) public view returns (uint48 since) {
        return roles[roleId].members[account];
    }

    /// @inheritdoc ISeparatedPowers
    function getAmountRoleHolders(uint32 roleId) public view returns (uint256 amountMembers) {
        return roles[roleId].amountMembers;
    }

    /// @inheritdoc ISeparatedPowers
    function executiveActionDeadline(uint256 actionId) public view virtual returns (uint256) {
        // uint48 + uint32 => uint256. £test if this works properly.
        return _executiveActions[actionId].voteStart + _executiveActions[actionId].voteDuration;
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
