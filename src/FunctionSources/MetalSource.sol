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
 * @title .sol
 * @author Ola Hamid
 * @notice THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION. (UNIT AND INTEGRATION TEST WIP).
 */

abstract contract MetalSource {
    string public getMetalMetadata =
        "const { ethers } = await import('npm:ethers@6.10.0');"
        "const Hash = await import('npm:ipfs-only-hash@4.0.0');"
        "const apiResponse = await Functions.makeHttpRequest({"
        "    url: `https://metals-api.com/api/latest?access_key=YOUR_METALS_API_KEY&base=USD&symbols=XAU,XAG`," // Replace with your API Key
        "});"
        "const goldPrice = Number(apiResponse.data.rates.XAU);"
        "const silverPrice = Number(apiResponse.data.rates.XAG);"
        "const metadata = {"
        "name: `Metal Token`," 
        "attributes: ["
        "{ trait_type: `Gold Price (USD)`, value: goldPrice },"
        "{ trait_type: `Silver Price (USD)`, value: silverPrice }"
        "]"
        "};"
        "const metadataString = JSON.stringify(metadata);"
        "const ipfsCid = await Hash.of(metadataString);"
        "return Functions.encodeString(`ipfs://${ipfsCid}`);";

    string public getMetalPrices =
        "const { ethers } = await import('npm:ethers@6.10.0');"
        "const abiCoder = ethers.AbiCoder.defaultAbiCoder();"
        "const metalType = args[0];" // For example, "Gold" or "Silver"
        "const apiResponse = await Functions.makeHttpRequest({"
        "    url: `https://metals-api.com/api/latest?access_key=YOUR_METALS_API_KEY&base=USD&symbols=XAU,XAG`," // Replace with your API Key
        "});"
        "const price = Number(metalType === 'Gold' ? apiResponse.data.rates.XAU : apiResponse.data.rates.XAG);"
        "const encoded = abiCoder.encode([`string`, `uint256`], [metalType, price]);"
        "return ethers.getBytes(encoded);";
}
