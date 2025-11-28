// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LearningSession.sol";

contract LearningSessionTest is Test {
    LearningSession internal session;

    address internal alice = address(0xA11CE);
    address internal bob   = address(0xB0B);
    address internal carol = address(0xCAro1);

    function setUp() public {
        session = new LearningSession();
    }

    // ------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------

    function _createRootVideo(address author, string memory cid) internal returns (uint256) {
        vm.prank(author);
        return session.createArtifact(
            LearningSession.LearningSessionArtifact.VIDEO,
            0,
            cid
        );
    }

    function _createComment(address author, uint256 parentId, string memory cid) internal returns (uint256) {
        vm.prank(author);
        return session.createArtifact(
            LearningSession.LearningSessionArtifact.COMMENT,
            parentId,
            cid
        );
    }

    // ------------------------------------------------------------
    // Artifact Creation
    // ------------------------------------------------------------

    function testCreateRootArtifact() public {
        string memory cid = "ipfs://root-video";
        uint256 beforeBlock = block.number;

        uint256 id = _createRootVideo(alice, cid);

        // Basic properties
        LearningSession.Artifact memory a = session.getArtifact(id);
        assertEq(a.id, id, "id mismatch");
        assertEq(uint8(a.artifactType), uint8(LearningSession.LearningSessionArtifact.VIDEO), "type mismatch");
        assertEq(a.parentId, 0, "root should have no parent");
        assertEq(a.author, alice, "author mismatch");
        assertEq(a.cid, cid, "cid mismatch");
        assertGe(a.createdAtBlock, beforeBlock, "createdAtBlock should not be in the past");
    }

    function testCreateCommentLinksToParent() public {
        uint256 rootId = _createRootVideo(alice, "ipfs://root-video");
        uint256 commentId = _createComment(bob, rootId, "ipfs://comment-1");

        // Check child artifact
        LearningSession.Artifact memory comment = session.getArtifact(commentId);
        assertEq(comment.parentId, rootId, "comment parentId mismatch");
        assertEq(comment.author, bob, "comment author mismatch");

        // Check parent childIds
        uint256[] memory childIds = session.getChildIds(rootId);
        assertEq(childIds.length, 1, "parent should have one child");
        assertEq(childIds[0], commentId, "child id mismatch");
    }

    function testRevertOnNonexistentParent() public {
        vm.prank(bob);
        vm.expectRevert("Parent does not exist");
        session.createArtifact(
            LearningSession.LearningSessionArtifact.COMMENT,
            999, // non-existent
            "ipfs://bad-parent"
        );
    }

    function testRevertOnNonexistentArtifactGet() public {
        vm.expectRevert("Artifact does not exist");
        session.getArtifact(1234);
    }

    function testRevertOnNonexistentChildIds() public {
        vm.expectRevert("Artifact does not exist");
        session.getChildIds(42);
    }

    // ------------------------------------------------------------
    // Voting Logic
    // ------------------------------------------------------------

    function testInitialVoteUpIncreasesScoreAndReputation() public {
        uint256 artifactId = _createRootVideo(alice, "ipfs://session1");

        vm.prank(bob);
        session.vote(artifactId, 1);

        int256 score = session.getArtifactScore(artifactId);
        int256 rep = session.getAuthorReputation(alice);

        assertEq(score, 1, "artifact score should be 1");
        assertEq(rep, 1, "author reputation should be 1");
    }

    function testDownvoteDecreasesScoreAndReputation() public {
        uint256 artifactId = _createRootVideo(alice, "ipfs://session1");

        vm.prank(bob);
        session.vote(artifactId, -1);

        int256 score = session.getArtifactScore(artifactId);
        int256 rep = session.getAuthorReputation(alice);

        assertEq(score, -1, "artifact score should be -1");
        assertEq(rep, -1, "author reputation should be -1");
    }

    function testChangingVoteAdjustsTotalsCorrectly() public {
        uint256 artifactId = _createRootVideo(alice, "ipfs://session1");

        // Bob upvotes (+1)
        vm.prank(bob);
        session.vote(artifactId, 1);

        // Score = 1, rep = 1
        assertEq(session.getArtifactScore(artifactId), 1, "score after +1");
        assertEq(session.getAuthorReputation(alice), 1, "rep after +1");

        // Bob changes to -1
        vm.prank(bob);
        session.vote(artifactId, -1);

        // Net change: -1 - (+1) = -2
        // Score should be -1; rep should be -1
        assertEq(session.getArtifactScore(artifactId), -1, "score after changing to -1");
        assertEq(session.getAuthorReputation(alice), -1, "rep after changing to -1");
    }

    function testWithdrawVoteResetsContribution() public {
        uint256 artifactId = _createRootVideo(alice, "ipfs://session1");

        // Bob upvotes
        vm.prank(bob);
        session.vote(artifactId, 1);

        assertEq(session.getArtifactScore(artifactId), 1, "score after +1");
        assertEq(session.getAuthorReputation(alice), 1, "rep after +1");

        // Bob withdraws vote (0)
        vm.prank(bob);
        session.vote(artifactId, 0);

        assertEq(session.getArtifactScore(artifactId), 0, "score after withdraw");
        assertEq(session.getAuthorReputation(alice), 0, "rep after withdraw");
    }

    function testSameVoteTwiceHasNoEffect() public {
        uint256 artifactId = _createRootVideo(alice, "ipfs://session1");

        vm.startPrank(bob);
        session.vote(artifactId, 1);
        int256 scoreAfterFirst = session.getArtifactScore(artifactId);
        int256 repAfterFirst = session.getAuthorReputation(alice);

        session.vote(artifactId, 1); // same vote again
        int256 scoreAfterSecond = session.getArtifactScore(artifactId);
        int256 repAfterSecond = session.getAuthorReputation(alice);
        vm.stopPrank();

        assertEq(scoreAfterFirst, 1);
        assertEq(repAfterFirst, 1);

        assertEq(scoreAfterSecond, 1, "score should not change");
        assertEq(repAfterSecond, 1, "rep should not change");
    }

    function testAuthorVotingDoesNotChangeOwnReputation() public {
        uint256 artifactId = _createRootVideo(alice, "ipfs://session1");

        vm.prank(alice);
        session.vote(artifactId, 1);

        int256 score = session.getArtifactScore(artifactId);
        int256 rep = session.getAuthorReputation(alice);

        // Score should still track the vote
        assertEq(score, 1, "score should reflect self-vote");

        // But reputation should not change when author == voter
        assertEq(rep, 0, "author reputation should not change from self-vote");
    }

    function testMultipleVotersAggregateCorrectly() public {
        uint256 artifactId = _createRootVideo(alice, "ipfs://session1");

        vm.prank(bob);
        session.vote(artifactId, 1);

        vm.prank(carol);
        session.vote(artifactId, -1);

        // Net score = +1 + (-1) = 0
        int256 score = session.getArtifactScore(artifactId);
        int256 rep = session.getAuthorReputation(alice);

        assertEq(score, 0, "net score should be 0");
        assertEq(rep, 0, "net reputation should be 0");
    }

    function testVoteOnNonexistentArtifactReverts() public {
        vm.prank(bob);
        vm.expectRevert("Artifact does not exist");
        session.vote(999, 1);
    }

    function testInvalidVoteValueReverts() public {
        uint256 artifactId = _createRootVideo(alice, "ipfs://session1");

        vm.prank(bob);
        vm.expectRevert("Invalid vote value");
        session.vote(artifactId, 2);
    }
}
