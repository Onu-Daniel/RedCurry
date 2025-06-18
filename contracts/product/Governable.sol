// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.22;

import "../product/Ownable.sol";

abstract contract Governable is Ownable {
    address[] private _governors;
    mapping(address => bool) private _isGovernor;
    
    event GovernorshipTransferred(
        address[] indexed previousGovernors,
        address[] indexed newGovernors
    );

    constructor(address[] memory governors_) Ownable() {
        _transferGovernorship(governors_);
    }

    /**
     * @dev Returns the address of the current governor.
     */
    function governors() public view virtual returns (address[] memory) {
        return _governors;
    }

    function isGovernor(address addr) public view returns (bool) {
        return _isGovernor[addr];
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        require(_isGovernor[_msgSender()], "Governable: caller is not a governor");
        _;
    }


    /**
     * @dev Transfers governorship of the contract to a new account (`newGovernor`).
     * Can only be called by the current governor.
     */
    function transferGovernorship(
        address[] memory newGovernors
    ) public virtual onlyOwner {
        require(newGovernors.length > 0, "Must have at least one governor");
        _transferGovernorship(newGovernors);
    }

    /**
     * @dev Transfers governorship of the contract to a new account (`newGovernor`).
     * Internal function without access restriction.
     */
    function _transferGovernorship(address[] memory newGovernors) internal virtual {
        // Clear existing mappings
        for (uint i = 0; i < _governors.length; i++) {
            _isGovernor[_governors[i]] = false;
        }

        // Set new governors and update mapping
        for (uint i = 0; i < newGovernors.length; i++) {
            require(newGovernors[i] != address(0), "Governable: zero address governor");
            _isGovernor[newGovernors[i]] = true;
        }

        address[] memory oldGovernors = _governors;
        _governors = newGovernors;

        emit GovernorshipTransferred(oldGovernors, newGovernors);
    }
    // function _transferGovernorship(
    //     address[] memory newGovernors
    // ) internal virtual {
    //     address[] memory oldGovernors = _governors;
    //     _governors = newGovernors;
        
    //     emit GovernorshipTransferred(oldGovernors, newGovernors);
    // }
}
