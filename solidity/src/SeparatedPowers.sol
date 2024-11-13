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
    mapping(uint256 proposalId => Proposal) private _proposals; // mapping from proposalId to proposal
    mapping(address lawAddress => LawConfig) public laws;
    mapping(uint48 roleId => Role) public roles;

    // two roles are preset: ADMIN_ROLE == 0 and PUBLIC_ROLE == type(uint48).max.
    uint48 public constant ADMIN_ROLE = type(uint48).min; // == 0
    uint48 public constant PUBLIC_ROLE = type(uint48).max; // == a lot
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
        // check: does msg.sender have access to targetLaw?
        uint32 allowedRole = laws[targetLaw].allowedRole;
        if (roles[allowedRole].members[msg.sender] == 0 && allowedRole != PUBLIC_ROLE) {
            revert SeparatedPowers__AccessDenied();
        }

        // check if the target law needs proposal to pass. 
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) =
            Law(targetLaw).executeLaw(msg.sender, lawCalldata, descriptionHash);
        // only if it needs a proposal will it return targetLaw as first target.  
        // £security: this check fails very easily: if you have a law that returns target as a first target. 
        // is this a problem? 
        if (targets[0] != targetLaw) {
            revert SeparatedPowers__LawDoesNotNeedProposal();
        }
        
        // if check passes: propose.
        return _propose(msg.sender, targetLaw, lawCalldata, description);
    }

    /// @notice Internal propose mechanism. Can be overridden to add more logic on proposal creation.
    ///
    /// @dev The mechanism checks for access of proposer and for the length of targets and calldatas.
    ///
    /// Emits a {SeperatedPowersEvents::ProposalCreated} event.
    function _propose(address proposer, address targetLaw, bytes memory lawCalldata, string memory description)
        internal
        virtual
        returns (uint256 proposalId)
    {
        // note that targetLaw AND proposer are hashed into the proposalId. By including proposer in the hash, front running a proposal is made impossible.
        proposalId = hashProposal(proposer, targetLaw, lawCalldata, keccak256(bytes(description)));
        if (_proposals[proposalId].voteStart == 0) {
            revert SeparatedPowers__UnexpectedProposalState();
        }

        uint32 duration = laws[targetLaw].votingPeriod;
        Proposal storage proposal = _proposals[proposalId];
        proposal.targetLaw = targetLaw;
        proposal.voteStart = uint48(block.number); // note that the moment proposal is made, voting start. There is no delay functionality.
        proposal.voteDuration = duration;

        emit ProposalCreated(
            proposalId, proposer, targetLaw, "", lawCalldata, block.number, block.number + duration, description
        );
    }

    /// @inheritdoc ISeparatedPowers
    function cancel(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        virtual
        returns (uint256)
    {
        uint256 proposalId = hashProposal(msg.sender, targetLaw, lawCalldata, descriptionHash);
        if (_proposals[proposalId].targetLaw == address(0)) {
            revert SeparatedPowers__InvalidProposalId();
        }
        if (_proposals[proposalId].completed || _proposals[proposalId].cancelled) {
            revert SeparatedPowers__UnexpectedProposalState();
        }
        if (msg.sender != _proposals[proposalId].proposer) {
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
        uint256 proposalId = hashProposal(msg.sender, targetLaw, lawCalldata, descriptionHash);

        if (_proposals[proposalId].targetLaw == address(0)) {
            revert SeparatedPowers__InvalidProposalId();
        }

        if (_proposals[proposalId].completed || _proposals[proposalId].cancelled) {
            revert SeparatedPowers__UnexpectedProposalState();
        }

        _proposals[proposalId].cancelled = true;
        emit ProposalCancelled(proposalId);

        return proposalId;
    }

    /// @inheritdoc ISeparatedPowers
    function execute(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash) external payable virtual {
        // check 1: does executioner have access to law being executed?
        uint32 allowedRole = laws[targetLaw].allowedRole;
        if (roles[allowedRole].members[msg.sender] == 0 && allowedRole != PUBLIC_ROLE) {
            revert SeparatedPowers__AccessDenied();
        }

        // calling target law: receiving targets, values and calldatas to execute.
        // Note that this call will revert if any conditions are not met.
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) =
            Law(targetLaw).executeLaw(msg.sender, lawCalldata, descriptionHash);

        // If the previous call was successful, execute.
        if (targets.length > 0 && targets[0] != targetLaw) {
            _executeOperations(targets, values, calldatas);
        }
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
    }

    /// @inheritdoc ISeparatedPowers
    function complete(address proposer, bytes memory lawCalldata, bytes32 descriptionHash) external virtual {
        // NB: £security CAN ANYONE call this function and set a proposal as completed?! 
        uint256 proposalId = hashProposal(proposer, msg.sender, lawCalldata, descriptionHash);

        _complete(proposalId);
    }

    /// @notice internal mechanism for setting a proposal as completed.
    /// runs through several checks before setting the proposal as completed.
    function _complete(uint256 proposalId) internal virtual {
        // check 1: is call from an active law?
        if (!laws[msg.sender].active) {
            revert SeparatedPowers__CompleteCallNotFromActiveLaw();
        }
        // check 2: does proposal exist?
        if (_proposals[proposalId].targetLaw == address(0)) {
            revert SeparatedPowers__InvalidProposalId();
        }
        // check 3: is proposal already completed?
        if (_proposals[proposalId].completed == true) {
            revert SeparatedPowers__ProposalAlreadyCompleted();
        }
        // check 4: is proposal cancelled?
        if (_proposals[proposalId].cancelled == true) {
            revert SeparatedPowers__ProposalCancelled();
        }

        // £todo: check if vote has passed?! // execution has been done?

        // if checks pass: complete & emit event.
        _proposals[proposalId].completed = true;
        emit ProposalCompleted(proposalId);
    }

    /// @inheritdoc ISeparatedPowers
    function castVote(uint256 proposalId, uint8 support) external virtual {
        address voter = msg.sender;
        return _castVote(proposalId, voter, support, "");
    }

    /// @inheritdoc ISeparatedPowers
    function castVoteWithReason(uint256 proposalId, uint8 support, string calldata reason) public virtual {
        address voter = msg.sender;
        return _castVote(proposalId, voter, support, reason);
    }

    /// @notice Internal vote casting mechanism.
    /// Check that the proposal is active, and that account is has access to targetLaw.
    ///
    /// Emits a {SeperatedPowersEvents::VoteCast} event.
    function _castVote(uint256 proposalId, address account, uint8 support, string memory reason) internal virtual {
        // Check that the proposal is active, that it has not been paused, cancelled or ended yet.
        if (SeparatedPowers(payable(address(this))).state(proposalId) != ProposalState.Active) {
            revert SeparatedPowers__ProposalNotActive();
        }
        // Note that we check if account has access to the law targetted in the proposal.
        address targetLaw = _proposals[proposalId].targetLaw;
        uint32 allowedRole = laws[targetLaw].allowedRole;
        if (roles[allowedRole].members[account] == 0 && allowedRole != PUBLIC_ROLE) {
            revert SeparatedPowers__AccessDenied();
        }
        // if all this passes: cast vote.
        _countVote(proposalId, account, support);

        emit VoteCast(account, proposalId, support, reason);
    }

    //////////////////////////////////////////////////////////////
    //                  ROLE AND LAW ADMIN                      //
    //////////////////////////////////////////////////////////////
    /// @inheritdoc ISeparatedPowers
    function constitute(
        // laws data
        address[] memory laws,
        uint32[] memory allowedRoles,
        uint8[] memory quorums,
        uint8[] memory succeedAts,
        uint32[] memory votingPeriods,
        // roles data
        uint48[] memory constituentRoles,
        address[] memory constituentAccounts
    ) external virtual {
        // check 1: only admin can call this function
        if (roles[ADMIN_ROLE].members[msg.sender] == 0) {
            revert SeparatedPowers__AccessDenied();
        }

        // check 2: check lengths of arrays
        if (
            laws.length != allowedRoles.length || laws.length != quorums.length || laws.length != succeedAts.length
                || laws.length != votingPeriods.length || constituentRoles.length != constituentAccounts.length
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
        for (uint256 i = 0; i < laws.length; i++) {
            _setLaw(laws[i], allowedRoles[i], quorums[i], succeedAts[i], votingPeriods[i]);
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
    function setRole(uint48 roleId, address account, bool access) public virtual onlySeparatedPowers {
        _setRole(roleId, account, access);
    }

    /// @notice Internal version of {setRole} without access control.
    ///
    /// Emits a {SeperatedPowersEvents::RolSet} event.
    function _setRole(uint48 roleId, address account, bool access) internal virtual {
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
    /// @param proposalId id of the proposal.
    /// @param targetLaw address of the law that the proposal belongs to.
    ///
    function _quorumReached(uint256 proposalId, address targetLaw) internal view virtual returns (bool) {
        Proposal storage proposal = _proposals[proposalId];

        uint8 quorum = laws[targetLaw].quorum;
        uint32 allowedRole = laws[targetLaw].allowedRole;
        uint256 amountMembers = roles[allowedRole].amountMembers;

        return (quorum == 0 || (amountMembers * quorum) / DENOMINATOR <= proposal.forVotes + proposal.abstainVotes);
    }

    /// @notice internal function {voteSucceeded} that checks if a vote for a given proposal has succeeded.
    ///
    /// @param proposalId id of the proposal.
    /// @param targetLaw address of the law that the proposal belongs to.
    function _voteSucceeded(uint256 proposalId, address targetLaw) internal view virtual returns (bool) {
        Proposal storage proposal = _proposals[proposalId];

        uint8 succeedAt = laws[targetLaw].succeedAt;
        uint8 quorum = laws[targetLaw].quorum;
        uint48 allowedRole = laws[targetLaw].allowedRole;
        uint256 amountMembers = roles[allowedRole].amountMembers;

        // note if quorum is set to 0 in a Law, it will automatically return true.
        return quorum == 0 || amountMembers * succeedAt <= proposal.forVotes * DENOMINATOR;
    }

    /// @notice internal function {countVote} that counts against, for, and abstain votes for a given proposal.
    ///
    /// @dev In this module, the support follows the `VoteType` enum (from Governor Bravo).
    /// @dev It does not check if account has roleId referenced in proposalId. This has to be done by {SeparatedPowers.castVote} function.
    function _countVote(uint256 proposalId, address account, uint8 support) internal virtual {
        Proposal storage proposal = _proposals[proposalId];

        if (proposal.hasVoted[account]) {
            revert SeparatedPowers__AlreadyCastVote(account);
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
    function hashProposal(address proposer, address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        pure
        virtual
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(proposer, targetLaw, lawCalldata, descriptionHash)));
    }

    //////////////////////////////////////////////////////////////
    //                      VIEW FUNCTIONS                      //
    //////////////////////////////////////////////////////////////
    /// @inheritdoc ISeparatedPowers
    function state(uint256 proposalId) public view virtual returns (ProposalState) {
        // We read the struct fields into the stack at once so Solidity emits a single SLOAD
        Proposal storage proposal = _proposals[proposalId];
        bool proposalCompleted = proposal.completed;
        bool proposalCancelled = proposal.cancelled;

        if (proposalCompleted) {
            return ProposalState.Completed;
        }
        if (proposalCancelled) {
            return ProposalState.Cancelled;
        }

        uint256 start = _proposals[proposalId].voteStart; // = startDate

        if (start == 0) {
            revert SeparatedPowers__InvalidProposalId();
        }

        uint256 deadline = proposalDeadline(proposalId);
        address targetLaw = proposal.targetLaw;

        if (deadline >= block.number) {
            return ProposalState.Active;
        } else if (!_quorumReached(proposalId, targetLaw) || !_voteSucceeded(proposalId, targetLaw)) {
            return ProposalState.Defeated;
        } else {
            return ProposalState.Succeeded;
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
    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool) {
        return _proposals[proposalId].hasVoted[account];
    }

    /// @inheritdoc ISeparatedPowers
    function proposalVotes(uint256 proposalId)
        public
        view
        virtual
        returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes)
    {
        Proposal storage proposal = _proposals[proposalId];
        return (proposal.againstVotes, proposal.forVotes, proposal.abstainVotes);
    }

    /// @inheritdoc ISeparatedPowers
    function hasRoleSince(address account, uint48 roleId) public view returns (uint48 since) {
        return roles[roleId].members[account];
    }

    /// @inheritdoc ISeparatedPowers
    function getAmountRoleHolders(uint48 roleId) public view returns (uint256 amountMembers) {
        return roles[roleId].amountMembers;
    }

    /// @inheritdoc ISeparatedPowers
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256) {
        // uint48 + uint32 => uint256. £test if this works properly.
        return _proposals[proposalId].voteStart + _proposals[proposalId].voteDuration;
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
