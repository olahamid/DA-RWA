// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library OALibrary {

    //////////////
    /// Errors ///
    //////////////
    error InvalidRetrieveData(bytes data);
    error InvalidManager(address caller, address manager);
    error RWAInvalidArrayLength(uint256 idLength, uint256 amountLength, uint256 uriLength);
    error RWAExceedMaxMint(uint256 requested, uint256 maximum);
    error RWAAssetAlreadyExists(uint256 id, string uri);
    error RWAInvalidBurnAsset(uint256 id, string uri);


    error OARWA_InvalidPlatformRigistration(bool isActive);
    error OARWA_InvalidAssetRegistration( bool isAssetRegistered);
    error OARWA_InvalidAssetRegistrastion(bool isAssetActive, bool isPlatfromActive);
    error OARWA_ZeroAddress();
    error OARWA_insufficientFee();
    error OARWA_FunctionSrcMethodError();

    event PlatformRegistered(address indexed platformAddress, string name, uint16 platformId);
    event AssetRegistered(address indexed platformAddress, uint16 assetId, string name);
    event PlatformKilled(address indexed platformAddress);
    event AssetKilled(address indexed platformAddress, uint16 assetId);
    event FunctionSourceCreated(address indexed functionSource, bytes32 jobId);

        /////////////////
    /// Events /////
    ////////////////
    event RWAManagerUpdated(address indexed oldManager, address indexed newManager);
    event TokenURISet(uint256 indexed id, string uri);
    event BatchMinted(address indexed to, uint256[] ids, uint256[] amounts);
    event BatchBurned(address indexed from, uint256[] ids, uint256[] amounts);
    event SingleMinted(address indexed to, uint256 indexed id, uint256 amount);
    event SingleBurned(address indexed from, uint256 indexed id, uint256 amount);
    event AssetCreated(
        address indexed creator,
        address indexed assetContract,
        uint256[] ids,
        uint256[] amounts
    );
    event FunctionSourceCreated(bytes32 indexed jobId, address functionSource);
    event PriceRequested(bytes32 indexed requestId, string assetName, uint256 price, uint256 timestamp);

   ///@notice these are various types of token asset on OA-RWAasset 
   enum AssetTypes {
    watches,
    vehicles,
    oilAndGas,
    stocks,
    realEstateAddress, 
    metalsAndStones,
    renewableEnergy
    }

    /// @notice datiled struct with diffeent properties for a creating a platform
    struct Platform {
    string PlatformName;
    uint16 PlatformID;
    bool isPlatformActive;
    address platformAddress;
    uint8 assetCount;
    }

    /// @notice datiled struct with diffeent properties for a creating an asset
    struct Asset {
    string AssetName;
    uint16 AssetID;
    AssetTypes AssetTypes;
    bool assetActive;
    address PlatformAddress;
    }

    struct AssetPrice {
        uint256 price;
        uint256 timestamp;
        string assetName;
        bool fulfilled;
    }
    struct APIAssetDetails {
        string assetName;      // Name of the asset
        string apiURL;         // Base URL for the API
        string headerData;     // API header information
        string endpointPath;   // Specific API endpoint path
        string requestMethod;  // HTTP method (GET, POST, etc.)
        bool isActive;         // Status of the endpoint
    }

    struct AssetCreationParams {
        Asset asset;              // Asset details
        uint256[] ids;           // Token IDs to mint
        uint256[] amounts;       // Amount of each token to mint
        bytes data;              // Additional data for minting
        string[] uris;           // URIs for each token
        address rwaManager;      // Manager address for RWA
        bytes platformBytes;     // Platform specific data
        bytes32 jobId;          // Unique job identifier
    }
}
