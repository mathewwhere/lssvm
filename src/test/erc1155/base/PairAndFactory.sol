// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {Configurable} from "../mixins/Configurable.sol";
import {Test721} from "../../../mocks/Test721.sol";
import {TestPairManager} from "../../../mocks/TestPairManager.sol";
import {Test1155} from "../../../mocks/Test1155.sol";
import {ICurve} from "../../../bonding-curves/ICurve.sol";
import {IERC721Mintable} from "../../interfaces/IERC721Mintable.sol";
import {IMintable} from "../../interfaces/IMintable.sol";
import {Test20} from "../../../mocks/Test20.sol";

import {LSSVMPair} from "../../../LSSVMPair.sol";
import {LSSVMPairERC1155Factory} from "../../../erc1155/LSSVMPairERC1155Factory.sol";

abstract contract PairAndFactory is DSTest, ERC721Holder, Configurable, ERC1155Holder {
}