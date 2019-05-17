pragma solidity ^0.4.24;

import "../ownership/ClaimableProxy.sol";

// Storage contracts holds all state.
// Do not change the order of the fields, аdd new fields to the end of the contract!
contract Storage is ClaimableProxy
{
    /***************************************************************************
     *** STORAGE VARIABLES. DO NOT REORDER!!! ADD NEW VARIABLE TO THE END!!! ***
     ***************************************************************************/

    struct AddressValue {
        bool initialized;
        address value;
    }

    mapping(address => mapping(bytes32 => AddressValue)) internal addressStorage;

    struct UintValue {
        bool initialized;
        uint value;
    }

    mapping(address => mapping(bytes32 => UintValue)) internal uintStorage;

    struct IntValue {
        bool initialized;
        int value;
    }

    mapping(address => mapping(bytes32 => IntValue)) internal intStorage;

    struct BoolValue {
        bool initialized;
        bool value;
    }

    mapping(address => mapping(bytes32 => BoolValue)) internal boolStorage;

    struct StringValue {
        bool initialized;
        string value;
    }

    mapping(address => mapping(bytes32 => StringValue)) internal stringStorage;

    struct BytesValue {
        bool initialized;
        bytes value;
    }

    mapping(address => mapping(bytes32 => BytesValue)) internal bytesStorage;

    struct BlockNumberValue {
        bool initialized;
        uint blockNumber;
    }

    mapping(address => mapping(bytes32 => BlockNumberValue)) internal txBytesStorage;

    bool private onlyFactProviderFromWhitelistAllowed;
    mapping(address => bool) private factProviderWhitelist;

    struct IPFSHashValue {
        bool initialized;
        string value;
    }

    mapping(address => mapping(bytes32 => IPFSHashValue)) internal ipfsHashStorage;

    struct PrivateData {
        string dataIPFSHash; // The IPFS hash of encrypted private data
        bytes32 dataKeyHash; // The hash of symmetric key that was used to encrypt the data
    }

    struct PrivateDataValue {
        bool initialized;
        PrivateData value;
    }

    mapping(address => mapping(bytes32 => PrivateDataValue)) internal privateDataStorage;

    enum PrivateDataExchangeState {Closed, Proposed, Accepted}

    struct PrivateDataExchange {
        address dataRequester;          // The address of the data requester
        uint256 dataRequesterValue;     // The amount staked by the data requester
        address passportOwner;          // The address of the passport owner at the time of the data exchange proposition
        uint256 passportOwnerValue;     // Tha amount staked by the passport owner
        address factProvider;           // The private data provider
        bytes32 key;                    // the key for the private data record
        string dataIPFSHash;            // The IPFS hash of encrypted private data
        bytes32 dataKeyHash;            // The hash of data symmetric key that was used to encrypt the data
        bytes encryptedExchangeKey;     // The encrypted exchange session key (only passport owner can decrypt it)
        bytes32 exchangeKeyHash;        // The hash of exchange session key
        bytes32 encryptedDataKey;       // The data symmetric key XORed with the exchange key
        PrivateDataExchangeState state; // The state of private data exchange
        uint256 stateExpired;           // The state expiration timestamp
    }

    uint public openPrivateDataExchangesCount; // the count of open private data exchanges TODO: use it in contract destruction/ownership transfer logic
    PrivateDataExchange[] public privateDataExchanges;

    /***************************************************************************
     *** END OF SECTION OF STORAGE VARIABLES                                 ***
     ***************************************************************************/

    event WhitelistOnlyPermissionSet(bool indexed onlyWhitelist);
    event WhitelistFactProviderAdded(address indexed factProvider);
    event WhitelistFactProviderRemoved(address indexed factProvider);

    /**
     *  Restrict methods in such way, that they can be invoked only by allowed fact provider.
     */
    modifier allowedFactProvider() {
        require(isAllowedFactProvider(msg.sender));
        _;
    }

    /**
     *  Returns true when the given address is an allowed fact provider.
     */
    function isAllowedFactProvider(address _address) public view returns (bool) {
        return !onlyFactProviderFromWhitelistAllowed || factProviderWhitelist[_address] || _address == _getOwner();
    }

    /**
     *  Returns true when a whitelist of fact providers is enabled.
     */
    function isWhitelistOnlyPermissionSet() external view returns (bool) {
        return onlyFactProviderFromWhitelistAllowed;
    }

    /**
     *  Enables or disables the use of a whitelist of fact providers.
     */
    function setWhitelistOnlyPermission(bool _onlyWhitelist) onlyOwner external {
        onlyFactProviderFromWhitelistAllowed = _onlyWhitelist;
        emit WhitelistOnlyPermissionSet(_onlyWhitelist);
    }

    /**
     *  Returns true if fact provider is added to the whitelist.
     */
    function isFactProviderInWhitelist(address _address) external view returns (bool) {
        return factProviderWhitelist[_address];
    }

    /**
     *  Allows owner to add fact provider to whitelist.
     */
    function addFactProviderToWhitelist(address _address) onlyOwner external {
        factProviderWhitelist[_address] = true;
        emit WhitelistFactProviderAdded(_address);
    }

    /**
     *  Allows owner to remove fact provider from whitelist.
     */
    function removeFactProviderFromWhitelist(address _address) onlyOwner external {
        delete factProviderWhitelist[_address];
        emit WhitelistFactProviderRemoved(_address);
    }
}