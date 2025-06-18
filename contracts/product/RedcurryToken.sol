// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.22;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../product/Governable.sol";

contract RedcurryToken is ERC20, Governable {
    event EscrowTransferred(
        address indexed previousEscrow,
        address indexed newEscrow
    );
    event TxnFeeChanged(uint256 newRateBps, uint256 newMax);

    bool private _canRedeem = true;
    bool private _canIssue = true;

    address private _escrow;

    uint public txnFeeRateBps = 2;
    uint public maxTxnFee = 25 * 10 ** 18; //25EUR
    uint constant MAX_UINT = 2 ** 256 - 1;
    uint constant TXN_FEE_BPS_LIMIT = 20;
    uint constant TXN_FEE_MAX_LIMIT = 50 * 10 ** 18; //50EUR

    constructor(
        address[] memory governors
    ) ERC20("RedcurryToken", "REDC") Governable(governors) {
        setEscrow(owner());
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }

    function setTxnFeeParams(
        uint256 newRateBps,
        uint256 newMax
    ) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newRateBps < TXN_FEE_BPS_LIMIT);
        require(newMax < TXN_FEE_MAX_LIMIT);

        txnFeeRateBps = newRateBps;
        maxTxnFee = newMax;

        emit TxnFeeChanged(txnFeeRateBps, maxTxnFee);
    }

    function canRedeem() public view returns (bool) {
        return _canRedeem;
    }

    function setCanRedeem(bool canRedeem_) public onlyOwner {
        _canRedeem = canRedeem_;
    }

    function canIssue() public view returns (bool) {
        return _canIssue;
    }

    function setCanIssue(bool canIssue_) public onlyOwner {
        _canIssue = canIssue_;
    }

    function setEscrow(address escrow_) public onlyOwner {
        require(escrow_ != address(0), "Token: escrow cannot be zero address");
        emit EscrowTransferred(_escrow, escrow_);
        _escrow = escrow_;
    }

    function getEscrow() public view returns (address) {
        return _escrow;
    }

    function issue(
        uint256 amount,
        address to
    ) public onlyGovernor returns (bool) {
        require(_canIssue, "Token: can not issue");
        if (to == address(0)) to = _escrow;
        _mint(to, amount);
        return true;
    }

    function redeem(uint256 amount) public virtual onlyGovernor returns (bool) {
        require(_canRedeem, "Token: can not redeem");
        require(balanceOf(_escrow) >= amount, "Token: insufficient escrow balance");

        _burn(_escrow, amount);
        return true;
    }

    function change(
        int256 amount,
        address recepient
    ) public onlyGovernor returns (bool) {
        require(recepient != address(0), "Token: recipient is zero address");

        if (amount > 0) {
            return issue(uint256(amount), recepient);
        } else {
            return redeem(uint256(-amount));
        }
    }

        function transfer(address to, uint256 amount) public override returns (bool) {
        address from = _msgSender();
        uint256 fee = _calculateFee(from, to, amount);
        uint256 amountAfterFee = amount - fee;

        _transfer(from, to, amountAfterFee);

        if (fee > 0) {
            _transfer(from, _escrow, fee);
        }

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        uint256 fee = _calculateFee(from, to, amount);
        uint256 amountAfterFee = amount - fee;

        _transfer(from, to, amountAfterFee);

        if (fee > 0) {
            _transfer(from, _escrow, fee);
        }

        return true;
    }

    function _calculateFee(address from, address to, uint256 amount) internal view returns (uint256 fee) {
        if (from == address(0) || to == address(0) || from == _escrow || to == _escrow) {
            return 0;
        }
        fee = (amount * txnFeeRateBps) / 10000;
        if (fee > maxTxnFee) {
            fee = maxTxnFee;
        }
    }

    // //txn fee logic is here
    // function _afterTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 amount
    // ) internal override {
    //     if (
    //         from == address(0) ||
    //         to == address(0) ||
    //         from == _escrow ||
    //         to == _escrow
    //     ) return;
    //     uint256 fee = (amount * txnFeeRateBps) / 10000;
    //     if (fee > maxTxnFee) {
    //         fee = maxTxnFee;
    //     }
    //     _transfer(to, _escrow, fee);
    //     super._afterTokenTransfer(from, to, amount);
    // }
}
