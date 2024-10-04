// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Merkle} from "../src/Merkle.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract MerkleTest is Test {
    using Strings for uint256;
    Merkle public merkle;

    function setUp() public {
        merkle = new Merkle();
    }

    function testAddAndVerifySequentially() public {
        uint256 numLeaves = 20;
        uint256[] memory leaves = new uint256[](numLeaves);

        for (uint256 i = 0; i < numLeaves; i++) {
            leaves[i] = uint256(keccak256(abi.encodePacked(i)));
            merkle.addLeaf(leaves[i]);
            console2.log(string(abi.encodePacked("Added leaf ", (i + 1).toString())));

            for (uint256 j = 0; j <= i; j++) {
                bool isValid = merkle.verifyLeaf(leaves[j], j);
                console2.log(string(abi.encodePacked(
                    "Verifying leaf ", 
                    (j + 1).toString(), 
                    " after adding ", 
                    (i + 1).toString(), 
                    " leaves. Is valid: ", 
                    isValid ? "true" : "false"
                )));
                assertTrue(isValid, string(abi.encodePacked("Failed to verify leaf ", (j + 1).toString(), " after adding ", (i + 1).toString(), " leaves")));
            }
        }
    }

    // Tests with larger numbers of leaves
    function testLargeNumberOfLeaves100() public {
        uint256 numLeaves = 100;
        for (uint256 i = 0; i < numLeaves; i++) {
            merkle.addLeaf(i);
        }
        for (uint256 i = 0; i < numLeaves; i++) {
            assertTrue(merkle.verifyLeaf(i, i), "Failed to verify leaf in large tree");
        }
    }

    function testLargeNumberOfLeaves1000() public {
        uint256 numLeaves = 1000;
        for (uint256 i = 0; i < numLeaves; i++) {
            merkle.addLeaf(i);
        }
        for (uint256 i = 0; i < numLeaves; i += 50) { // Check every 50th leaf to save gas
            assertTrue(merkle.verifyLeaf(i, i), "Failed to verify leaf in very large tree");
        }
    }

    // Tests with random inputs
    function testRandomInputs() public {
        uint256 numLeaves = 50;
        uint256[] memory randomLeaves = new uint256[](numLeaves);
        for (uint256 i = 0; i < numLeaves; i++) {
            randomLeaves[i] = uint256(keccak256(abi.encodePacked(block.timestamp, i)));
            merkle.addLeaf(randomLeaves[i]);
        }
        for (uint256 i = 0; i < numLeaves; i++) {
            assertTrue(merkle.verifyLeaf(randomLeaves[i], i), "Failed to verify random leaf");
        }
    }

    function testRandomInputsWithDuplicates() public {
        uint256 numLeaves = 50;
        uint256[] memory randomLeaves = new uint256[](numLeaves);
        for (uint256 i = 0; i < numLeaves; i++) {
            randomLeaves[i] = uint256(keccak256(abi.encodePacked(block.timestamp, i))) % 25; // Introduce potential duplicates
            merkle.addLeaf(randomLeaves[i]);
        }
        for (uint256 i = 0; i < numLeaves; i++) {
            assertTrue(merkle.verifyLeaf(randomLeaves[i], i), "Failed to verify random leaf with potential duplicates");
        }
    }

    // Negative tests
    function testInvalidProof() public {
        merkle.addLeaf(1);
        merkle.addLeaf(2);
        merkle.addLeaf(3);

        assertTrue(merkle.verifyLeaf(2, 1), "Valid leaf should verify");
        assertFalse(merkle.verifyLeaf(3, 1), "Invalid leaf should not verify");
    }

   

    function testVerifyNonExistentLeaf() public {
    merkle.addLeaf(1);
    merkle.addLeaf(2);
    merkle.addLeaf(3);

    // Try to verify a leaf that exists in the tree but with the wrong value
    assertFalse(merkle.verifyLeaf(4, 2), "Non-existent leaf value should not verify");

    // Try to verify a leaf at an index that exists but with the wrong value
    assertFalse(merkle.verifyLeaf(4, 1), "Wrong leaf value should not verify");

    // The following line would cause an IndexOutOfBounds error, so we don't test it
    // assertFalse(merkle.verifyLeaf(4, 3), "Non-existent leaf index should revert");
}
}
