// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VestingToken is Ownable {
    IERC20 public vestingtoken;

    struct VestingSchedule {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 cliffDuration;
        uint256 duration;
        uint256 startTime;
    }

    mapping(address => VestingSchedule) public vestingSchedules;

    // Custom errors
    error VestingScheduleAlreadyExists(address beneficiary);
    error VestingScheduleNotExists(address beneficiary);
    error AmountExceedsTotalAmount(uint256 amount, uint256 totalAmount);
    error AmountCannotBeZero();
    error StartTimeCannotBeInThePast(uint256 startTime);
    error CliffDurationCannotBeGreaterThanDuration(uint256 cliffDuration, uint256 duration);
    error CliffDurationCannotBeZero();
    error DurationCannotBeZero();
    error StartTimeCannotBeZero();
    error CannotSetVestingSchedule(address beneficiary);
    error CliffNotReached(uint256 cliffDuration);
    error NothingToClaim(uint256 claimable);

    constructor(address _token) Ownable(msg.sender) {
        vestingtoken = IERC20(_token);
    }

    function setVestingSchedule(
        address _beneficiary,
        uint256 _totalAmount,
        uint256 _cliffDuration,
        uint256 _duration,
        uint256 _startTime
    ) external onlyOwner {
        if (vestingSchedules[_beneficiary].totalAmount > 0) {
            revert VestingScheduleAlreadyExists(_beneficiary);
        }
        if (_totalAmount == 0) {
            revert AmountCannotBeZero();
        }
        if (_startTime < block.timestamp) {
            revert StartTimeCannotBeInThePast(_startTime);
        }
        if (_cliffDuration > _duration) {
            revert CliffDurationCannotBeGreaterThanDuration(_cliffDuration, _duration);
        }
        if (_cliffDuration == 0) {
            revert CliffDurationCannotBeZero();
        }
        if (_duration == 0) {
            revert DurationCannotBeZero();
        }
        if (_startTime == 0) {
            revert StartTimeCannotBeZero();
        }

        vestingSchedules[_beneficiary] = VestingSchedule({
            totalAmount: _totalAmount,
            claimedAmount: 0,
            cliffDuration: _cliffDuration,
            duration: _duration,
            startTime: _startTime
        });

        bool success = vestingtoken.transferFrom(msg.sender, address(this), _totalAmount);
        require(success, "Transfer failed");
    }

    function claimVesting() external {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];

        if (schedule.totalAmount == 0) {
            revert VestingScheduleNotExists(msg.sender);
        }
        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            revert CliffNotReached(schedule.cliffDuration);
        }

        uint256 elapsed = block.timestamp - schedule.startTime;
        uint256 releasableAmount = (schedule.totalAmount * elapsed) / schedule.duration;

        if (releasableAmount > schedule.totalAmount) {
            releasableAmount = schedule.totalAmount;
        }

        uint256 claimable = releasableAmount - schedule.claimedAmount;

        if (claimable == 0) {
            revert NothingToClaim(claimable);
        }

        schedule.claimedAmount += claimable;

        bool success = vestingtoken.transfer(msg.sender, claimable);
        require(success, "Transfer failed");
    }

    function getAmountVested(address _beneficiary) external view returns (uint256 releasableAmount) {
        VestingSchedule storage schedule = vestingSchedules[_beneficiary];

        if (schedule.totalAmount == 0) {
            revert VestingScheduleNotExists(_beneficiary);
        }
        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            revert CliffNotReached(schedule.cliffDuration);
        }

        uint256 elapsed = block.timestamp - schedule.startTime;
        releasableAmount = (schedule.totalAmount * elapsed) / schedule.duration;

        if (releasableAmount > schedule.totalAmount) {
            releasableAmount = schedule.totalAmount;
        }

        return releasableAmount;
    }

    function getClaimable(address user) external view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[user];

        if (schedule.totalAmount == 0) {
            revert VestingScheduleNotExists(user);
        }
        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            revert CliffNotReached(schedule.cliffDuration);
        }

        uint256 elapsed = block.timestamp - schedule.startTime;
        uint256 releasable = (elapsed * schedule.totalAmount) / schedule.duration;

        if (releasable > schedule.totalAmount) {
            releasable = schedule.totalAmount;
        }

        return releasable - schedule.claimedAmount;
    }
}
