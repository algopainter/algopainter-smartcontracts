// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IAlgoPainterItem {
    function getName(uint256 _algoPainterId)
        external
        view
        returns (string memory);

    function getCurrentAmount(uint256 _algoPainterId, uint256 _reference)
        external
        returns (uint256);

    function getTokenBytes32ConfigParameter(
        uint256 _algoPainterId,
        uint256 _tokenId,
        uint256 _parameter
    ) external view returns (bytes32);

    function getTokenUint256ConfigParameter(
        uint256 _algoPainterId,
        uint256 _tokenId,
        uint256 _parameter
    ) external view returns (uint256);

    function getTokenStringConfigParameter(
        uint256 _algoPainterId,
        uint256 _tokenId,
        uint256 _parameter
    ) external view returns (string memory);

    function getTokenBooleanConfigParameter(
        uint256 _algoPainterId,
        uint256 _tokenId,
        uint256 _parameter
    ) external view returns (bool);

    function getPIRS(uint256 _algoPainterId, uint256 _tokenId)
        external
        returns (uint256);

    function getCollectedTokenAmount(uint256 _algoPainterId)
        external
        view
        returns (uint256);

    function getTokenAmountToBurn(uint256 _algoPainterId)
        external
        returns (uint256);

    function allowedTokens(uint256 _algoPainterId)
        external
        view
        returns (address[] memory);
}
