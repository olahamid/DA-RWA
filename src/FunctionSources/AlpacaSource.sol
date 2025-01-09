// Layout:
//     - pragma
//     - imports
//     - interfaces, libraries, contracts
//     - type declarations
//     - state variables
//     - events
//     - errors
//     - modifiers
//     - functions
//         - constructor
//         - receive function (if exists)
//         - fallback function (if exists)
//         - external
//         - public
//         - internal
//         - private
//         - view and pure functions


// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
/**
 * @title AlpacaSource.sol
 * @author Ola Hamid
 * @notice THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION. (UNIT AND INTEGRATION TEST WIP).
 */

abstract contract AlpacaSource {
    string public getStockMetadata =
        "const { ethers } = await import('npm:ethers@6.10.0');"
        "const Hash = await import('npm:ipfs-only-hash@4.0.0');"
        "const apiResponse = await Functions.makeHttpRequest({"
        "    url: `https://data.alpaca.markets/v2/stocks/AAPL/quote?access_token=YOUR_ALPACA_API_KEY`," // Replace with your API Key
        "});"
        "const stockSymbol = apiResponse.data.symbol;"
        "const lastPrice = Number(apiResponse.data.last.price);"
        "const askPrice = Number(apiResponse.data.ask_price);"
        "const bidPrice = Number(apiResponse.data.bid_price);"
        "const metadata = {"
        "name: `Stock Token`," 
        "attributes: ["
        "{ trait_type: `Stock Symbol`, value: stockSymbol },"
        "{ trait_type: `Last Price`, value: lastPrice },"
        "{ trait_type: `Ask Price`, value: askPrice },"
        "{ trait_type: `Bid Price`, value: bidPrice }"
        "]"
        "};"
        "const metadataString = JSON.stringify(metadata);"
        "const ipfsCid = await Hash.of(metadataString);"
        "return Functions.encodeString(`ipfs://${ipfsCid}`);";

    string public getStockPrices =
        "const { ethers } = await import('npm:ethers@6.10.0');"
        "const abiCoder = ethers.AbiCoder.defaultAbiCoder();"
        "const stockSymbol = args[0];"
        "const apiResponse = await Functions.makeHttpRequest({"
        "    url: `https://data.alpaca.markets/v2/stocks/${stockSymbol}/quote?access_token=YOUR_ALPACA_API_KEY`," // Replace with your API Key
        "});"
        "const lastPrice = Number(apiResponse.data.last.price);"
        "const askPrice = Number(apiResponse.data.ask_price);"
        "const bidPrice = Number(apiResponse.data.bid_price);"
        "const encoded = abiCoder.encode([`string`, `uint256`, `uint256`, `uint256`], [stockSymbol, lastPrice, askPrice, bidPrice]);"
        "return ethers.getBytes(encoded);";
}
