// SPDX-License-Identifier: MIT

/// @notice The core contract of the SeparatedPowers protocol. Inherits from {LawsManager}, {AuthoritiesManager} and {Law}.
/// Code derived from OpenZeppelin's Governor.sol contract.
///
/// Note that originally, Governor.sol is abstract and needs modules to be added to function. In contrast, SeparatedPowers is not set as abstract and is self-contained.
/// Any additional functionality should be brought in through laws.
/// Although the protocol does allow functions to be updated in inhereted contracts, this should be avoided if possible.
///
/// The protocol is meant to be inherited by a contract that implements a DAO. See for an example {implementation/AgDao.sol}.
///
/// Other differences:
/// - No ERC165 in the core protocol, this can change later. Laws do support ERC165 interfaces.
/// - The use of {clock} is removed. Only blocknumbers are used at the moment, no timestamps.
/// - There is currently no protection against front-running proposals.
/// - The contract structure is different than the one used by OpenZeppelin's Governor.sol. See the end of this contract for the structure I followed.
///
/// @author 7Cedars, Oct 2024, RnDAO CollabTech Hackathon
pragma solidity 0.8.26;

import { Law } from "./Law.sol";
import { ILaw } from "./interfaces/ILaw.sol";
import { ISeparatedPowers } from "./interfaces/ISeparatedPowers.sol";
import { ERC165Checker } from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { Address } from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import { EIP712 } from "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import { SeparatedPowersErrors } from "./interfaces/SeparatedPowersErrors.sol";
import { SeparatedPowersEvents } from "./interfaces/SeparatedPowersEvents.sol";

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
    uint256 constant DENOMINATOR = 100;

    string private _name; // name of the DAO.
    bool private _constituentLawsExecuted; // has the constitute function been called before.

    //////////////////////////////////////////////////////////////
    //                          MODIFIERS                       //
    //////////////////////////////////////////////////////////////
    /// @notice A modifier that sets a function to only be callable by the {SeparatedPowers} contract itself.
    ///
    /// @dev It can used in derived contracts to easily protect functions from being called from outside the protocol.
    modifier onlySeparatedPowers() {
        if (msg.sender != address(this)) {
            revert SeparatedPowers__OnlySeparatedPowers();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //              CONSTRUCTOR & RECEIVE                       //
    //////////////////////////////////////////////////////////////
    /// @notice  Sets the value for {name} and {version} at the time of construction.
    ///
    /// @param name_ name of the contract
    constructor(string memory name_) EIP712(name_, version()) {
        _name = name_;
        _setRole(ADMIN_ROLE, msg.sender, true); // the account that initiates a SeparatedPowers contract is set to its admin.

        roles[ADMIN_ROLE].amountMembers = 1; // the number of admins at set up is 1. 
        roles[PUBLIC_ROLE].amountMembers = type(uint256).max; // the number for holders of the PUBLIC_ROLE is type(uint256).max. 

        emit SeparatedPowers__Initialized(address(this));
    }

    /// @notice receive function enabling ETH deposits.
    ///
    /// @dev This is a virtual function, and can be overridden in child contracts.
    /// @dev No access control on this function: anyone can send funds into the main contract.
    receive() external payable virtual {
        emit FundsReceived(msg.value);
    }

    //////////////////////////////////////////////////////////////
    //                  GOVERNANCE LOGIC                        //
    //////////////////////////////////////////////////////////////
    /// @dev see {ISeperatedPowers.propose}
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

        // if check passes: propose.
        return _propose(msg.sender, targetLaw, lawCalldata, description);
    }

    /// @notice Internal propose mechanism. Can be overridden to add more logic on proposal creation.
    ///
    /// @dev The mechanism checks for access of proposer and for the length of targets and calldatas.
    ///
    /// Emits a {ProposalCreated} event.
    function _propose(address proposer, address targetLaw, bytes memory lawCalldata, string memory description)
        internal
        virtual
        returns (uint256 proposalId)
    {
        (bool passed) = Law(targetLaw).checkDependencies(msg.sender, lawCalldata, keccak256(bytes(description)));
        if (!passed) {
            revert SeparatedPowers__LawCheckFailed();
        }

        // note that targetLaw AND proposer are hashed into the proposalId. By including proposer in the hash, front running is avoided.
        proposalId = hashProposal(targetLaw, lawCalldata, keccak256(bytes(description)));
        if (_proposals[proposalId].voteStart != 0) {
            revert SeparatedPowers__UnexpectedProposalState();
        }

        uint32 duration = laws[targetLaw].votingPeriod;
        Proposal storage proposal = _proposals[proposalId];
        proposal.targetLaw = targetLaw;
        proposal.voteStart = uint48(block.number); // at the moment proposal is made, voting start. There is no delay functionality.
        proposal.voteDuration = duration;

        emit ProposalCreated(
            proposalId, proposer, targetLaw, "", lawCalldata, block.number, block.number + duration, description
        );
    }

    /// @dev See {IseperatedPowers.cancel}
    function cancel(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        virtual
        returns (uint256)
    {
        // check: is call from an active law? -- Note that this 
        if (!laws[msg.sender].active) {
            revert SeparatedPowers__CancelCallNotFromActiveLaw();
        }

        return _cancel(targetLaw, lawCalldata, descriptionHash);
    }

    /// @notice Internal cancel mechanism with minimal restrictions. A proposal can be cancelled in any state other than
    /// Cancelled or Executed. Once cancelled a proposal can't be re-submitted.
    ///
    /// Emits a {ISeperatedPowers-ProposalCanceled} event.
    function _cancel(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        internal
        virtual
        returns (uint256)
    {
        uint256 proposalId = hashProposal(targetLaw, lawCalldata, descriptionHash);

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

    /// @dev see {ISeperatedPowers.execute}
    ///
    /// Note any reference to proposal (as in OpenZeppelin's Governor.sol) are removed.
    /// The mechanism of SeparatedPowers detaches proposals from execution logic.
    /// Instead, proposal checks are placed in the {complete} function which is called by laws.
    function execute(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash) external payable virtual {
        // check 1: does executioner have access to law being executed?
        uint32 allowedRole = laws[targetLaw].allowedRole;
        if (roles[allowedRole].members[msg.sender] == 0 && allowedRole != PUBLIC_ROLE) {
            revert SeparatedPowers__AccessDenied();
        }

        // calling target law: receiving targets, values and calldatas to execute.
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) =
            Law(targetLaw).executeLaw(msg.sender, lawCalldata, descriptionHash);

        // execute.
        if (targets.length > 0) {
            _executeOperations(targets, values, calldatas);
        }
    }

    /// @notice Internal execution mechanism. Can be overridden (without a super call) to modify the way execution is
    /// performed
    ///
    /// NOTE: Calling this function directly will NOT check the current state of the proposal, set the executed flag to
    /// true or emit the `ProposalExecuted` event. Executing a proposal should be done using {execute} or {_execute}.
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

    /// @dev see {ISeperatedPowers.complete}
    function complete(bytes memory lawCalldata, bytes32 descriptionHash) external virtual {
        uint256 proposalId = hashProposal(msg.sender, lawCalldata, descriptionHash);

        _complete(proposalId);
    }

    /// @dev see {ISeperatedPowers.complete}
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

        // if checks pass: complete & emit event.
        _proposals[proposalId].completed = true;
        emit ProposalCompleted(proposalId);
    }

    /// @dev See {ISeperatedPowers.castVote}.
    function castVote(uint256 proposalId, uint8 support) external virtual {
        address voter = msg.sender;
        return _castVote(proposalId, voter, support, "");
    }

    /// @dev See {ISeperatedPowers.castVoteWithReason}.
    function castVoteWithReason(uint256 proposalId, uint8 support, string calldata reason) public virtual {
        address voter = msg.sender;
        return _castVote(proposalId, voter, support, reason);
    }

    /// @notice Internal vote casting mechanism: Check that the proposal is active, and that account is has access to targetLaw.
    ///
    /// Emits a {ISeperatedPowers-VoteCast} event.
    function _castVote(uint256 proposalId, address account, uint8 support, string memory reason) internal virtual {
        // Check that the proposal is active, that it has not been paused, cancelled or ended yet.
        if (SeparatedPowers(payable(address(this))).state(proposalId) != ProposalState.Active) {
            revert SeparatedPowers__ProposalNotActive();
        }
        // Note that we check if account has access to the law targetted in the proposal.
        address targetLaw = _proposals[proposalId].targetLaw;
        uint32 allowedRole = laws[targetLaw].allowedRole;
        if (roles[allowedRole].members[account] == 0 && allowedRole != PUBLIC_ROLE) {
            revert SeparatedPowers__NoAccessToTargetLaw();
        }
        // if all this passes: cast vote.
        _countVote(proposalId, account, support);

        emit VoteCast(account, proposalId, support, reason);
    }

    //////////////////////////////////////////////////////////////
    //                  ROLE AND LAW ADMIN                      //
    //////////////////////////////////////////////////////////////
    /// @dev see {ISeperatedPowers.constitute}
    // NB: Note that constituentRoles is now an addressp[][]: an array of arrays of addresses. 
    // Each index of the top array corresponds to a RoleId. 
    // Each index of the bottom array corresponds to an address.
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
            laws.length != allowedRoles.length || 
            laws.length != quorums.length ||
            laws.length != succeedAts.length ||
            laws.length != votingPeriods.length || 
            constituentRoles.length != constituentAccounts.length
            ) {
            revert SeparatedPowers__InvalidArrayLengths();
        }

        // check 3: this function can only be called once.
        if (_constituentLawsExecuted) {
            revert SeparatedPowers__ConstitutionAlreadyExecuted();
        }

        // if checks pass, set _constituentLawsExecuted to true...
        _constituentLawsExecuted = true;

        // £TODO refactor  
        // ...and execute constitutional laws
        for (uint256 i = 0; i < laws.length; i++) {
            _setLaw(laws[i], allowedRoles[i], quorums[i], succeedAts[i], votingPeriods[i]);
        }
        for (uint256 i = 0; i < constituentRoles.length; i++) {
            _setRole(constituentRoles[i], constituentAccounts[i], true);
        }
    }

    // £TODO Is it possible to create a function {createLaw} that takes as input a constructor data and returns an address?
    // all laws have the same interface 
    /// @dev {see ... }
    function setLaw(
        address law, 
        uint32 allowedRole,
        uint8 quorum,
        uint8 succeedAt, 
        uint32 votingPeriod
        ) public { 
        // check is caller the protocol?
        if (msg.sender != address(this)) {
            revert SeparatedPowers__NotAuthorized();
        }

        _setLaw(law, allowedRole, quorum, succeedAt, votingPeriod);
    }

    /// @dev {see ILawsManager.setLaw}
    function revokeLaw(address law) public {
        // check is caller the protocol?
        if (msg.sender != address(this)) {
            revert SeparatedPowers__NotAuthorized();
        }

        if (!laws[law].active) {
            revert SeparatedPowers__LawNotActive();
        }
        
        emit LawRevoked(law); 
        laws[law].active = false;
    }

    /// @notice internal function to set a law to active or inactive.
    ///
    /// params = £todo 
    ///
    /// @dev this function can only be called from the execute function of SeperatedPowers.sol.
    ///
    /// returns bool lawChanged, true if the law is set as active.
    ///
    /// emits a LawSet event.
    function _setLaw(
        address law, 
        uint32 allowedRole,
        uint8 quorum,
        uint8 succeedAt, 
        uint32 votingPeriod
        ) internal virtual {
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

    /// @dev see {IAuthoritiesManager.setRole}
    function assignRole(uint48 roleId, address account) public virtual {
        // this function can only be called from within SeperatedPowers.
        if (msg.sender != address(this)) {
            revert SeparatedPowers__NotAuthorized();
        }
        _setRole(roleId, account, true);
    }

    /// @dev see {IAuthoritiesManager.setRole}
    function revokeRole(uint48 roleId, address account) public virtual {
        // this function can only be called from within SeperatedPowers.
        if (msg.sender != address(this)) {
            revert SeparatedPowers__NotAuthorized();
        }
        _setRole(roleId, account, false);
    }

    /// @notice Internal version of {setRole} without access control. Returns true if the role was newly granted.
    ///
    /// Emits a {RoleGranted} event.
    function _setRole(uint48 roleId, address account, bool access) internal virtual {
        bool newMember = roles[roleId].members[account] == 0;
        bool accessChanged;

        if (access && newMember) {
            roles[roleId].members[account] = uint48(block.number); // 'since' is set at current block.number
            roles[roleId].amountMembers++;
            accessChanged = true;
        } else if (!access && !newMember) {
            roles[roleId].members[account] = 0;
            roles[roleId].amountMembers--;
            accessChanged = true;
        }

        emit RoleSet(roleId, account, accessChanged);
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

        return
            quorum == 0 || (amountMembers * quorum) / DENOMINATOR <= proposal.forVotes + proposal.abstainVotes;
    }
    
    /// @dev internal function {voteSucceeded} that checks if a vote for a given proposal has succeeded.
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

    /// @dev see {ISeperatedPowers.hashProposal}
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
    /// @dev see {ISeperatedPowers.state}
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
            revert SeperatedPowers__NonExistentProposal(proposalId);
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

    /// @notice saves the name of the SeparatedPowers implementation.
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /// @notice saves the version of the SeparatedPowers implementation.
    function version() public pure returns (string memory) {
        return "1";
    }

    /// @notice public function {canCallLaw} that checks if a caller can call a given law.
    ///
    /// @param caller address of the caller.
    /// @param targetLaw address of the law to check.
    function canCallLaw(address caller, address targetLaw) public view returns (bool) {
        uint32 allowedRole = laws[targetLaw].allowedRole;
        uint48 since = hasRoleSince(caller, allowedRole);

        return since != 0;
    }

    /// @dev see {IAuthoritiesManager.hasVoted}
    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool) {
        return _proposals[proposalId].hasVoted[account];
    }

    /// @dev see {IAuthoritiesManager.proposals}
    function proposalVotes(uint256 proposalId)
        public
        view
        virtual
        returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes)
    {
        Proposal storage proposal = _proposals[proposalId];
        return (proposal.againstVotes, proposal.forVotes, proposal.abstainVotes);
    }

    /// @dev see {IAuthoritiesManager.hasRoleSince}
    function hasRoleSince(address account, uint48 roleId) public view returns (uint48 since) {
        return roles[roleId].members[account];
    }

    function getAmountRoleHolders(uint48 roleId) public view returns (uint256 amountMembers) {
        return roles[roleId].amountMembers;
    }

    /// @dev See {ISeperatedPowers.proposalDeadline}
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256) {
        return _proposals[proposalId].voteStart + _proposals[proposalId].voteDuration;
    }

    /// @dev {see ILawsManager.getActiveLaw}
    function getActiveLaw(address law) external view returns (bool active) {
        return laws[law].active;
    }

    //////////////////////////////////////////////////////////////
    //                       COMPLIENCE                         //
    //////////////////////////////////////////////////////////////
    /// @dev See {IERC721Receiver-onERC721Received}.
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @dev See {IERC1155Receiver-onERC1155Received}.
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @dev See {IERC1155Receiver-onERC1155BatchReceived}.
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        virtual
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
