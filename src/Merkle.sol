// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {console} from "forge-std/console.sol"; 

/// @title MerkleStorage
/// @notice A contract for storing and verifying elements in a Merkle tree
/// @dev This contract allows adding leaves to a Merkle tree, updating the root, and verifying leaf inclusion
contract Merkle {
    bytes32[] private leafArray;
    bytes32 private merkleRoot;

    error IndexOutOfBounds(uint256 index, uint256 length);
    
    event LeafAdded(bytes32 indexed leaf, uint256 indexed index);
    event MerkleRootUpdated(bytes32 indexed newRoot);

    /// @notice Adds a new leaf to the Merkle tree
    /// @param leaf The value to be added as a leaf
    /// @dev Converts the uint256 to bytes32, adds it to the tree, and updates the Merkle root
    function addLeaf(uint256 leaf) public {
        bytes32 leafHash = bytes32(leaf);
        leafArray.push(leafHash);
        emit LeafAdded(leafHash, leafArray.length - 1);
        updateMerkleRoot();
    }

    /// @notice Verifies if a leaf exists in the Merkle tree
    /// @param leaf The leaf value to verify
    /// @param index The index of the leaf in the tree
    /// @return bool True if the leaf is verified, false otherwise
    /// @dev Reverts if the index is out of bounds
    function verifyLeaf(uint256 leaf, uint256 index) public view returns (bool) {
        if (index >= leafArray.length) revert IndexOutOfBounds(index, leafArray.length);
        
        bytes32 leafHash = bytes32(leaf);
        bytes32[] memory proof = getProof(index);
        return MerkleProof.verify(proof, merkleRoot, leafHash);
    }

    /// @notice Retrieves the current Merkle root
    /// @return bytes32 The current Merkle root
    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    /// @notice Gets the total number of leaves in the Merkle tree
    /// @return uint256 The number of leaves
    function getLeafCount() external view returns (uint256) {
        return leafArray.length;
    }

    /// @notice Retrieves a specific leaf from the Merkle tree
    /// @param index The index of the leaf to retrieve
    /// @return bytes32 The leaf value at the specified index
    /// @dev Reverts if the index is out of bounds
    function getLeaf(uint256 index) external view returns (bytes32) {
        if (index >= leafArray.length) revert IndexOutOfBounds(index, leafArray.length);
        return leafArray[index];
    }

    /// @dev Updates the Merkle root based on the current leaves
    function updateMerkleRoot() private {
        uint256 n = leafArray.length;
        bytes32[] memory currentLevel = leafArray;

        while (n > 1) {
            uint256 halfN = (n + 1) / 2;
            bytes32[] memory nextLevel = new bytes32[](halfN);
            for (uint256 i = 0; i < n - 1; i += 2) {
                nextLevel[i / 2] = hashPair(currentLevel[i], currentLevel[i + 1]);
            }
            if (n % 2 == 1) {
                nextLevel[halfN - 1] = currentLevel[n - 1];
            }
            currentLevel = nextLevel;
            n = halfN;
        }

        merkleRoot = currentLevel[0];
        emit MerkleRootUpdated(merkleRoot);
    }

    /// @dev Generates the Merkle proof for a leaf at a given index
    /// @param index The index of the leaf
    /// @return bytes32[] The Merkle proof
    function getProof(uint256 index) private view returns (bytes32[] memory) {
        if (index >= leafArray.length) revert IndexOutOfBounds(index, leafArray.length);

        uint256 depth = getTreeDepth(leafArray.length);
        bytes32[] memory proof = new bytes32[](depth);
        uint256 proofIndex = 0;

        bytes32[] memory currentLevel = leafArray;

        for (uint256 i = 0; i < depth; i++) {
            uint256 levelSize = currentLevel.length;
            bytes32[] memory nextLevel = new bytes32[]((levelSize + 1) / 2);

            uint256 indexInLevel = index;
            for (uint256 j = 0; j < levelSize; j += 2) {
                if (j == indexInLevel) {
                    if (j + 1 < levelSize) {
                        proof[proofIndex++] = currentLevel[j + 1];
                    }
                } else if (j + 1 == indexInLevel) {
                    proof[proofIndex++] = currentLevel[j];
                }

                if (j + 1 < levelSize) {
                    nextLevel[j / 2] = hashPair(currentLevel[j], currentLevel[j + 1]);
                } else {
                    nextLevel[j / 2] = currentLevel[j];
                }
            }

            currentLevel = nextLevel;
            index /= 2;
        }

        // Trim the proof array to remove any unused elements
        bytes32[] memory trimmedProof = new bytes32[](proofIndex);
        for (uint256 i = 0; i < proofIndex; i++) {
            trimmedProof[i] = proof[i];
        }

        return trimmedProof;
    }

    /// @dev Calculates the depth of the Merkle tree
    /// @param n The number of leaves in the tree
    /// @return uint256 The depth of the tree
    function getTreeDepth(uint256 n) private pure returns (uint256) {
        uint256 depth = 0;
        while (n > 1) {
            n = (n + 1) / 2;
            depth++;
        }
        return depth;
    }

    /// @dev Hashes a pair of bytes32 values in a consistent order
    /// @param a The first value
    /// @param b The second value
    /// @return bytes32 The hash of the pair
    function hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? efficientHash(a, b) : efficientHash(b, a);
    }

    /// @dev Efficiently hashes two bytes32 values using assembly
    /// @param a The first value
    /// @param b The second value
    /// @return value The hash of the two values
    function efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}