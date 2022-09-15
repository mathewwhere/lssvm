// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {LSSVMPair} from "../../../LSSVMPair.sol";
import {ICurve} from "../../../bonding-curves/ICurve.sol";
import {IERC721Mintable} from "../../interfaces/IERC721Mintable.sol";
import {LSSVMPairERC1155Factory} from "../../../erc1155/LSSVMPairERC1155Factory.sol";

abstract contract Configurable {
    function getBalance(address a) public virtual returns (uint256);

    function setupPair(
        LSSVMPairERC1155Factory factory,
        IERC1155 nft,
        ICurve bondingCurve,
        address payable assetRecipient,
        LSSVMPair.PoolType poolType,
        uint128 delta,
        uint96 fee,
        uint128 spotPrice,
        uint256[] memory _idList,
        uint256 initialTokenBalance,
        address routerAddress /* Yes, this is weird, but due to how we encapsulate state for a Pair's ERC20 token, this is an easy way to set approval for the router.*/
    ) public payable virtual returns (LSSVMPair);

    function setupCurve() public virtual returns (ICurve);

    function setup1155() public virtual returns (IERC721Mintable);

    function modifyInputAmount(uint256 inputAmount)
        public
        virtual
        returns (uint256);

    function modifyDelta(uint64 delta) public virtual returns (uint64);

    function modifySpotPrice(uint56 spotPrice) public virtual returns (uint56);

    function sendTokens(LSSVMPair pair, uint256 amount) public virtual;

    function withdrawTokens(LSSVMPair pair) public virtual;

    function withdrawProtocolFees(LSSVMPairERC1155Factory factory) public virtual;

    receive() external payable {}
}
