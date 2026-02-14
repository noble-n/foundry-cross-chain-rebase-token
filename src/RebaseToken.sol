//SPDX-License-Identifier: MIT

// LAYOUT OF CONTRACT:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
 * @title RebaseToken
 * @author Nwabuike Noble
 * @notice This is a cross-chain rebase token that incentivises users to deposit into a vault and gain interest in rewards.
 * @notice The interest rate in the smart contract can only decrease
 * @notice Each will user will have their own interest rate that is the global interest rate at the time of depositing.
 */
contract RebaseToken is ERC20 {
    //Errors
    error RebaseToken__InterestRateCanOnlyDecrease(
        uint256 oldInterestRate,
        uint256 newInterestRate
    );

    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) public s_userInterestRate;
    
    mapping(address => uint256) public s_userLastUpdatedTimeStamp;

    //events
    event interestRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") {}

    /**
     * @notice Set the interest rate in the contract
     * @param _newInterestRate The new interest rate to set
     * @dev The interest rate can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external {
        if (_newInterestRate < s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(
                s_interestRate,
                _newInterestRate
            );
        }
        s_interestRate = _newInterestRate;
        emit interestRateSet(_newInterestRate);
    }
    //
    function mint(address _to, uint256 _amount) external {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /**
     * @dev returns the global interest rate of the token for future depositors
     * @return s_interestRate
     *
     */
    function getUserInterestRate(
        address _user
    ) external view returns (uint256) {}

    function balanceOf(address _user) public view override returns (uint256) {
        //get current principle balance of the user 
        return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user) / PRECISION_FACTOR;

    }

    function _mintAccruedInterest(address _user) internal {
        // Get the user's previous principal balance. The amount of tokens they had last time their interest was minted to them.
        s_userLastUpdatedTimeStamp[_user] = block.timestamp;
    }

    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns (uint256 linearInterest){
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimeStamp[_user];
        linearInterest = (PRECISION_FACTOR + (s_userInterestRate[_user]) * timeElapsed);
    }
}
