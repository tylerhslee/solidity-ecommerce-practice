// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
    @title Decentralized marketplace to buy and sell any product
    @author Tyler H. S. Lee
    @notice WIP

    1. each time buyer buys product, buy order is created
    2. supplier must fulfill each order to receive payment
    3. funds are withheld by the contract until order is fulfilled
    4. potential to define SLAs for order fulfillment
*/
contract Marketplace {
    
    struct Listing {
        string name;
        string category;
        string imageUrl;
        bool orderFulfilled;
        uint price;
        address supplier;
        address buyer;
    }

    mapping (address => Listing[]) supplierToListings;

    /**
        @param wallet Address from which posting is made (supplier == wallet)

        potential to connect to mobile app for identity verification; prevent multi-wallet scams by making
        it possible to identify collection of wallets to single individual
    */
    modifier isWalletOwner (address wallet) {
        require(wallet == msg.sender);
        _;
    }

    event Received(address, uint);

    receive () external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback () external payable {}

    /**
        @param name Name of listing
        @param category Category of listing; potential to pre-determine list of valid product categories
        @param imgUrl URL to product images (should be downloadable by simple GET)
        @param price Total price of listing
        @param supplier Wallet address of supplier
    */
    function postNewListing (
        string memory name,
        string memory category,
        string memory imgUrl,
        uint price,
        address supplier
    ) public isWalletOwner(supplier) {
        Listing memory newListing = Listing(name, category, imgUrl, false, price, supplier, address(0));
        Listing[] storage supplierOwnListings = supplierToListings[supplier];
        supplierOwnListings.push(newListing);
    }

    /**
        @dev retrieve list of listings posted by the supplier
        @param supplier supplier address
        @return list of listings
    */
    function getListingsBySupplier (address supplier) public view returns (Listing[] memory) {
        return supplierToListings[supplier];
    }

    /**
        @dev find a specific listing given supplier and listing id (index of listing)
        @param supplier supplier address
        @param listingId index of listing in supplierToListings array
        @return listing by the supplier
    */
    function getOneListing (address supplier, uint listingId) public view returns (Listing memory) {
        return getListingsBySupplier(supplier)[listingId];
    }

    /**
        @dev create a pending buy order; send any change back to the buyer in case frontend does not send exact amount
        @param supplier supplier address
        @param listingId index of listing in supplierToListings array
        @return success/fail of purchase (possible to fail if the listing has no pending order)
    */
    function buyListing(address supplier, uint listingId) external payable returns (bool) {
        address payable buyer = payable(msg.sender);
        Listing storage listing = supplierToListings[supplier][listingId];
        if (!listing.orderFulfilled && listing.buyer == address(0)) {
            require(listing.price <= msg.value);
            if (msg.value > listing.price) {
                buyer.transfer(msg.value - listing.price);
            }
            listing.buyer = buyer;
            return true;
        }
        return false;
    }

    /**
        @dev fulfill orders on a given listing; only works if there is a buyer
        @param listingId index of listing in supplierToListings array
    */
    function fillOrder(uint listingId) external {
        Listing storage listing = supplierToListings[msg.sender][listingId];
        if (!listing.orderFulfilled && listing.buyer != address(0)) {
            address payable supplier = payable(msg.sender);
            // somehow verify order fulfillment in real life
            // maybe use tracking number?
            supplier.transfer(listing.price);
            listing.orderFulfilled = true;
        }
    }

}