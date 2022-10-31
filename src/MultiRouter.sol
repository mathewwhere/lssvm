// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {LSSVMPair} from "./LSSVMPair.sol";
import {ILSSVMPairFactoryLike} from "./ILSSVMPairFactoryLike.sol";
import {CurveErrorCodes} from "./bonding-curves/CurveErrorCodes.sol";
import {ILSSVMPairERC1155FactoryLike} from "./erc1155/ILSSVMPairERC1155FactoryLike.sol";

contract MultiRouter {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    ILSSVMPairFactoryLike public immutable erc721factory;
    ILSSVMPairERC1155FactoryLike public immutable erc1155Factory;

    constructor(
        ILSSVMPairFactoryLike _erc721factory,
        ILSSVMPairERC1155FactoryLike _erc1155Factory
    ) {
        erc721factory = _erc721factory;
        erc1155Factory = _erc1155Factory;
    }

    struct PairSwapSpecific {
        LSSVMPair pair;
        uint256[] nftIds;
    }

    struct RobustPairSwapSpecificWithToken {
        PairSwapSpecific swapInfo;
        uint256 maxCost;
        bool isETHSwap;
    }

    struct RobustPairSwapSpecificForToken {
        PairSwapSpecific swapInfo;
        uint256 minOutput;
    }

    struct RobustPairNFTsForTokenAndTokenforNFTsTrade {
        RobustPairSwapSpecificWithToken[] tokenToNFTTradesSpecific;
        RobustPairSwapSpecificForToken[] nftToTokenTrades;
    }

    /**
        @notice Buys NFTs with ETH and ERC20s and sells them for tokens in one transaction
        @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
        - tokenToNFTTradesSpecific The list of NFTs to buy 
        - nftToTokenSwapList The list of NFTs to sell (we cheat a little, and pack the amount into the ID field for ID-agnostic sells)
        - inputAmount The max amount of tokens to send (if ERC20)
        - tokenRecipient The address that receives tokens from the NFTs sold
        - nftRecipient The address that receives NFTs
     */
    function robustSwapTokensForSpecificNFTsAndNFTsToToken(
        RobustPairNFTsForTokenAndTokenforNFTsTrade calldata params
    ) external payable returns (uint256 remainingValue, uint256 outputAmount) {
        // Attempt to fill each buy order for specific NFTs (used for ERC721 and ERC1155-many-id)
        {
            remainingValue = msg.value;
            uint256 pairCost;
            CurveErrorCodes.Error error;

            // Try doing each swap
            // TODO: this currently doesn't track the quote for the number of items correctly because it uses LENGTH instead of VALUE for erc1155
            uint256 numSwaps = params.tokenToNFTTradesSpecific.length;
            for (uint256 i; i < numSwaps; ) {
                // Calculate actual cost per swap
                (error, , , pairCost, ) = params
                    .tokenToNFTTradesSpecific[i]
                    .swapInfo
                    .pair
                    .getBuyNFTQuote(
                        params
                            .tokenToNFTTradesSpecific[i]
                            .swapInfo
                            .nftIds
                            .length
                    );

                // If within our maxCost and no error, proceed
                if (
                    pairCost <= params.tokenToNFTTradesSpecific[i].maxCost &&
                    error == CurveErrorCodes.Error.OK
                ) {
                    // We know how much ETH to send because we already did the math above
                    // So we just send that much
                    if (params.tokenToNFTTradesSpecific[i].isETHSwap) {
                        remainingValue -= params
                            .tokenToNFTTradesSpecific[i]
                            .swapInfo
                            .pair
                            .swapTokenForSpecificNFTs{value: pairCost}(
                            params.tokenToNFTTradesSpecific[i].swapInfo.nftIds,
                            pairCost,
                            msg.sender,
                            true,
                            msg.sender
                        );
                    } 
                    // Otherwise we send ERC20 tokens
                    else {
                        params
                            .tokenToNFTTradesSpecific[i]
                            .swapInfo
                            .pair
                            .swapTokenForSpecificNFTs(
                                params
                                    .tokenToNFTTradesSpecific[i]
                                    .swapInfo
                                    .nftIds,
                                pairCost,
                                msg.sender,
                                true,
                                msg.sender
                            );
                    }
                }

                unchecked {
                    ++i;
                }
            }
            // Return remaining value to sender
            if (remainingValue > 0) {
                payable(msg.sender).safeTransferETH(remainingValue);
            }
        }
        // Attempt to fill each sell order (for ERC721 and ERC1155-many-id)
        // For ERC1155-single-id, we abuse the RobustPairSwapSpecific struct and encode
        // the number of items to swap for as the value in a single item array of length 1
        // TODO: this currently doesn't track the quote for the number of items correctly because it uses LENGTH instead of VALUE for erc1155
        {
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps; ) {
                uint256 pairOutput;

                // Locally scoped to avoid stack too deep error
                {
                    CurveErrorCodes.Error error;
                    (error, , , pairOutput, ) = params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pair
                        .getSellNFTQuote(
                            params.nftToTokenTrades[i].swapInfo.nftIds.length
                        );
                    if (error != CurveErrorCodes.Error.OK) {
                        unchecked {
                            ++i;
                        }
                        continue;
                    }
                }

                // If at least equal to our minOutput, proceed
                if (pairOutput >= params.nftToTokenTrades[i].minOutput) {
                    // Do the swap and update outputAmount with how many tokens we got
                    outputAmount += params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pair
                        .swapNFTsForToken(
                            params.nftToTokenTrades[i].swapInfo.nftIds,
                            0,
                            payable(msg.sender),
                            true,
                            msg.sender
                        );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    receive() external payable {}

    /**
        Restricted functions
     */

    /**
        @dev Allows an ERC20 pair contract to transfer ERC20 tokens directly from
        the sender, in order to minimize the number of token transfers. Only callable by an ERC20 pair.
        @param token The ERC20 token to transfer
        @param from The address to transfer tokens from
        @param to The address to transfer tokens to
        @param amount The amount of tokens to transfer
        @param variant The pair variant of the pair contract
     */
    function pairTransferERC20From(
        ERC20 token,
        address from,
        address to,
        uint256 amount,
        uint8 variant
    ) external {
        // verify pair
        if (variant < 4) {
            // ERC721 pair
            // verify caller is a trusted pair contract
            ILSSVMPairFactoryLike.PairVariant _variant = ILSSVMPairFactoryLike
                .PairVariant(variant);
            require(erc721factory.isPair(msg.sender, _variant), "Not pair");

            // verify caller is an ERC20 pair
            require(
                _variant ==
                    ILSSVMPairFactoryLike.PairVariant.ENUMERABLE_ERC20 ||
                    _variant ==
                    ILSSVMPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ERC20,
                "Not ERC20 pair"
            );
        } else {
            // ERC1155 pair
            // verify caller is a trusted pair contract
            ILSSVMPairERC1155FactoryLike.PairVariant _variant = ILSSVMPairERC1155FactoryLike
                    .PairVariant(variant);
            require(erc1155Factory.isPair(msg.sender, _variant), "Not pair");

            // verify caller is an ERC20 pair
            require(
                _variant ==
                    ILSSVMPairERC1155FactoryLike.PairVariant.SINGLE_ID_ERC20 ||
                    _variant ==
                    ILSSVMPairERC1155FactoryLike.PairVariant.MANY_ID_ERC20,
                "Not ERC20 pair"
            );
        }

        // transfer tokens to pair
        token.safeTransferFrom(from, to, amount);
    }

    /**
        @dev Allows a pair contract to transfer ERC721 NFTs directly from
        the sender, in order to minimize the number of token transfers. Only callable by a pair.
        @param nft The ERC721 NFT to transfer
        @param from The address to transfer tokens from
        @param to The address to transfer tokens to
        @param id The ID of the NFT to transfer
        @param variant The pair variant of the pair contract
     */
    function pairTransferNFTFrom(
        IERC721 nft,
        address from,
        address to,
        uint256 id,
        ILSSVMPairFactoryLike.PairVariant variant
    ) external {
        // verify caller is a trusted pair contract
        require(erc721factory.isPair(msg.sender, variant), "Not pair");
        // transfer NFTs to pair
        nft.safeTransferFrom(from, to, id);
    }

    function pairTransferERC1155From(
        IERC1155 nft,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        ILSSVMPairERC1155FactoryLike.PairVariant variant
    ) external {
        // verify caller is a trusted pair contract
        require(erc1155Factory.isPair(msg.sender, variant), "Not pair");
        nft.safeBatchTransferFrom(from, to, ids, amounts, bytes(""));
    }
}
