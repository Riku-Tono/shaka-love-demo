// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ShakaLoveDemo
 * @notice Demo-only creative smart contract for heartbeat synchronization claims.
 * @dev
 * This contract is preserved as a memorial / technical exhibit artifact.
 *
 * SAFETY NOTICE:
 * - Not audited.
 * - Not intended for production.
 * - Not intended for mainnet deployment.
 * - Not a financial product, payment method, token sale, or investment.
 * - The LOVE token in this demo has no promised value, utility, or redemption.
 * - Do not use with real private keys, real funds, or production oracle systems.
 *
 * Concept:
 * - Heartbeat synchronization as proof
 * - Oracle-signed attestations
 * - Demo reward minting
 */

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract ShakaLoveDemo is ERC20, Ownable, Pausable, ReentrancyGuard, EIP712 {
    struct Attestation {
        bytes32 sessionId;
        address subject;
        address partner;
        uint64 startTs;
        uint64 endTs;
        uint16 syncScoreBps;
        uint256 reward;
        uint256 deadline;
    }

    error BadAddress();
    error BadAttestation();
    error BadLimit();
    error BadSignature();
    error Cooldown();
    error DailyLimit();
    error Expired();
    error NoOverlap();
    error NotParticipant();
    error SessionUsed();
    error SyncTooLow();

    bytes32 private constant ATTESTATION_TYPEHASH = keccak256(
        "Attestation(bytes32 sessionId,address subject,address partner,uint64 startTs,uint64 endTs,uint16 syncScoreBps,uint256 reward,uint256 deadline)"
    );

    uint16 public constant MIN_SYNC_BPS = 9300;
    uint64 public constant MIN_OVERLAP_SECONDS = 30;
    uint256 public constant MAX_REWARD_PER_SUBJECT = 10 ether;

    address public oracleSigner;
    uint256 public dailyMintLimit;
    uint256 public mintedToday;
    uint256 public lastResetDay;
    uint256 public cooldownSeconds;

    mapping(bytes32 => bool) public usedSession;
    mapping(bytes32 => uint256) public lastClaimByPair;

    event OracleSignerUpdated(address indexed signer);
    event DailyMintLimitUpdated(uint256 limit);
    event CooldownUpdated(uint256 seconds_);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);
    event CoupleClaimed(
        bytes32 indexed sessionId,
        bytes32 indexed pairKey,
        address indexed subjectA,
        address subjectB,
        uint256 rewardEach
    );

    constructor(address initialOwner, address initialOracleSigner, uint256 initialDailyMintLimit, uint256 initialCooldownSeconds)
        ERC20("Shaka Love Demo", "LOVE")
        Ownable(initialOwner)
        EIP712("ShakaLoveDemo", "1")
    {
        if (initialOwner == address(0) || initialOracleSigner == address(0)) revert BadAddress();
        if (initialDailyMintLimit == 0) revert BadLimit();
        oracleSigner = initialOracleSigner;
        dailyMintLimit = initialDailyMintLimit;
        cooldownSeconds = initialCooldownSeconds;
        lastResetDay = block.timestamp / 1 days;
    }

    function claimCouple(Attestation calldata a, bytes calldata sigA, Attestation calldata b, bytes calldata sigB)
        external
        whenNotPaused
        nonReentrant
    {
        if (a.sessionId != b.sessionId) revert BadAttestation();
        if (usedSession[a.sessionId]) revert SessionUsed();

        _validateCouple(a, b);

        if (msg.sender != a.subject && msg.sender != b.subject) revert NotParticipant();
        if (block.timestamp > a.deadline || block.timestamp > b.deadline) revert Expired();

        _validateReward(a, b);
        _validateSync(a, b);

        uint64 overlap = _overlapSeconds(a.startTs, a.endTs, b.startTs, b.endTs);
        if (overlap < MIN_OVERLAP_SECONDS) revert NoOverlap();

        _verify(a, sigA);
        _verify(b, sigB);

        bytes32 pairKey = _pairKey(a.subject, b.subject);
        _checkCooldown(pairKey);

        usedSession[a.sessionId] = true;
        lastClaimByPair[pairKey] = block.timestamp;
        _checkDailyMint(a.reward * 2);

        _mint(a.subject, a.reward);
        _mint(b.subject, a.reward);

        emit CoupleClaimed(a.sessionId, pairKey, a.subject, b.subject, a.reward);
    }

    function setOracleSigner(address signer) external onlyOwner {
        if (signer == address(0)) revert BadAddress();
        oracleSigner = signer;
        emit OracleSignerUpdated(signer);
    }

    function setDailyMintLimit(uint256 limit) external onlyOwner {
        // Setting this to zero intentionally pauses new claims without pausing transfers.
        dailyMintLimit = limit;
        emit DailyMintLimitUpdated(limit);
    }

    function setCooldownSeconds(uint256 seconds_) external onlyOwner {
        cooldownSeconds = seconds_;
        emit CooldownUpdated(seconds_);
    }

    function pause() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpause() external onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    function hashAttestation(Attestation calldata a) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ATTESTATION_TYPEHASH,
                    a.sessionId,
                    a.subject,
                    a.partner,
                    a.startTs,
                    a.endTs,
                    a.syncScoreBps,
                    a.reward,
                    a.deadline
                )
            )
        );
    }

    function _validateCouple(Attestation calldata a, Attestation calldata b) internal pure {
        if (a.subject == address(0) || b.subject == address(0) || a.subject == b.subject) revert BadAttestation();
        if (a.partner != b.subject || b.partner != a.subject) revert BadAttestation();
    }

    function _validateSync(Attestation calldata a, Attestation calldata b) internal pure {
        if (a.syncScoreBps < MIN_SYNC_BPS || b.syncScoreBps < MIN_SYNC_BPS) revert SyncTooLow();
    }

    function _validateReward(Attestation calldata a, Attestation calldata b) internal pure {
        if (a.reward == 0 || a.reward > MAX_REWARD_PER_SUBJECT || b.reward != a.reward) revert BadAttestation();
    }

    function _checkCooldown(bytes32 pairKey) internal view {
        if (lastClaimByPair[pairKey] != 0 && block.timestamp < lastClaimByPair[pairKey] + cooldownSeconds) {
            revert Cooldown();
        }
    }

    function _verify(Attestation calldata a, bytes calldata sig) internal view {
        address recovered = ECDSA.recover(hashAttestation(a), sig);
        if (recovered != oracleSigner) revert BadSignature();
    }

    function _checkDailyMint(uint256 amount) internal {
        uint256 today = block.timestamp / 1 days;
        if (today > lastResetDay) {
            mintedToday = 0;
            lastResetDay = today;
        }
        if (mintedToday + amount > dailyMintLimit) revert DailyLimit();
        mintedToday += amount;
    }

    function _overlapSeconds(uint64 startA, uint64 endA, uint64 startB, uint64 endB) internal pure returns (uint64) {
        if (startA >= endA || startB >= endB) revert BadAttestation();
        uint64 start = startA > startB ? startA : startB;
        uint64 end = endA < endB ? endA : endB;
        return end > start ? end - start : 0;
    }

    function _pairKey(address x, address y) internal pure returns (bytes32) {
        (address a, address b) = x < y ? (x, y) : (y, x);
        return keccak256(abi.encode(a, b));
    }
}
