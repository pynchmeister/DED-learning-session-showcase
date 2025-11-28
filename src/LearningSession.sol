---

## 3️⃣ `src/LearningSession.sol` (Safe, Minimal Showcase Contract)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DED Learning Session (Showcase Version)
/// @notice Minimal, non-economic example of learning artifacts + voting + reputation.
/// @dev This is a simplified public demo, not the full DED protocol.
contract LearningSession {
    // ------------------------------------------------------------
    // Types
    // ------------------------------------------------------------

    /// @notice Type of artifact in a learning session.
    enum LearningSessionArtifact {
        VIDEO,
        COMMENT
    }

    /// @notice Core artifact type representing a learning session output or discussion item.
    struct Artifact {
        LearningSessionArtifact artifactType;
        uint256 id;
        uint256 parentId;        // 0 if no parent (root)
        address author;
        uint256 createdAtBlock;
        uint256[] childIds;
        string cid;              // off-chain content identifier (e.g. IPFS/Filecoin)
    }

    /// @notice Per-artifact voting state.
    struct ArtifactVotes {
        int256 total;                     // net score = sum(votes)
        mapping(bytes32 => int8) votes;   // voterId => last vote (-1, 0, +1)
    }

    // ------------------------------------------------------------
    // Storage
    // ------------------------------------------------------------

    /// @notice All artifacts by id.
    mapping(uint256 => Artifact) private artifacts;

    /// @notice Voting data for each artifact.
    mapping(uint256 => ArtifactVotes) private artifactVotes;

    /// @notice Aggregated reputation per author.
    mapping(address => int256) private authorReputation;

    /// @notice Incremental artifact id counter.
    uint256 private nextArtifactId = 1;

    // ------------------------------------------------------------
    // Events
    // ------------------------------------------------------------

    event ArtifactCreated(
        uint256 indexed id,
        uint256 indexed parentId,
        address indexed author,
        LearningSessionArtifact artifactType,
        string cid
    );

    event Voted(
        uint256 indexed artifactId,
        address indexed voter,
        int8 oldVote,
        int8 newVote
    );

    // ------------------------------------------------------------
    // Public View Functions
    // ------------------------------------------------------------

    /// @notice Get a full artifact by id.
    function getArtifact(uint256 artifactId) external view returns (Artifact memory) {
        require(artifacts[artifactId].id == artifactId, "Artifact does not exist");
        return artifacts[artifactId];
    }

    /// @notice Get the child ids for a given artifact.
    function getChildIds(uint256 artifactId) external view returns (uint256[] memory) {
        require(artifacts[artifactId].id == artifactId, "Artifact does not exist");
        return artifacts[artifactId].childIds;
    }

    /// @notice Get the aggregated score for an artifact.
    function getArtifactScore(uint256 artifactId) external view returns (int256) {
        return artifactVotes[artifactId].total;
    }

    /// @notice Get total reputation for an author across all artifacts.
    function getAuthorReputation(address author) external view returns (int256) {
        return authorReputation[author];
    }

    // ------------------------------------------------------------
    // Core Mutations
    // ------------------------------------------------------------

    /// @notice Create a new artifact (video or comment).
    /// @param artifactType The type of artifact (VIDEO or COMMENT).
    /// @param parentId The parent artifact id (0 if none).
    /// @param cid Off-chain content identifier (e.g. IPFS/Filecoin CID).
    function createArtifact(
        LearningSessionArtifact artifactType,
        uint256 parentId,
        string calldata cid
    ) external returns (uint256) {
        uint256 id = nextArtifactId++;
        Artifact storage a = artifacts[id];

        a.artifactType = artifactType;
        a.id = id;
        a.parentId = parentId;
        a.author = msg.sender;
        a.createdAtBlock = block.number;
        a.cid = cid;

        // If this artifact is a reply/comment, register it on the parent.
        if (parentId != 0) {
            require(artifacts[parentId].id == parentId, "Parent does not exist");
            artifacts[parentId].childIds.push(id);
        }

        emit ArtifactCreated(id, parentId, msg.sender, artifactType, cid);
        return id;
    }

    /// @notice Vote on an artifact with a value in {-1, 0, +1}.
    /// @dev This is a simple, non-economic reputation system.
    /// @param artifactId The id of the artifact being voted on.
    /// @param voteValue The vote value: -1 (downvote), 0 (withdraw), +1 (upvote).
    function vote(uint256 artifactId, int8 voteValue) external {
        require(artifacts[artifactId].id == artifactId, "Artifact does not exist");
        require(voteValue >= -1 && voteValue <= 1, "Invalid vote value");

        bytes32 voterId = _voterId(msg.sender);
        ArtifactVotes storage v = artifactVotes[artifactId];

        int8 oldVote = v.votes[voterId];

        if (oldVote == voteValue) {
            // No change, do nothing.
            return;
        }

        v.votes[voterId] = voteValue;
        v.total = v.total - oldVote + voteValue;

        address author = artifacts[artifactId].author;
        if (author != msg.sender) {
            authorReputation[author] = authorReputation[author] - oldVote + voteValue;
        }

        emit Voted(artifactId, msg.sender, oldVote, voteValue);
    }

    // ------------------------------------------------------------
    // Internal Helpers
    // ------------------------------------------------------------

    /// @notice Derive a voter id from an address. In a more complex system this
    ///         could be replaced by an identity scheme (e.g. DIDs, badges, etc).
    function _voterId(address voter) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(voter));
    }
}
