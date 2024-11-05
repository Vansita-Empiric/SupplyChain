// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract Supply {
    address owner;

    struct Product {
        bytes4 id;
        uint256 price;
        string productInfo;
        ProductState state;
        MemberType lastUpdateBy;
        address addressOfSigner;
        address payable shipper;
        address transporter;
        address consigner;
    }

    enum MemberType {
        Shipper,
        Transporter,
        Consigner
    }

    enum ProductState {
        Packed,
        Dispatched,
        Delivered
    }

    struct Member {
        string name;
        address memberAddress;
        MemberType memberType;
    }

    Member[] members;

    mapping(address => Member) getMember;

    mapping(address => bool) isShipper;
    mapping(address => bool) isTransporter;
    mapping(address => bool) isConsigner;

    Product[] allProducts;
    bytes4[] productIds;

    mapping(bytes4 => Product) product;

    constructor() {
        owner = msg.sender;
    }

    function addMember(
        string memory _memberName,
        address _memberAddress,
        MemberType _memberType
    ) public {
        require(_memberAddress != address(0), "Zero address not allowed");
        require(_memberAddress != owner, "Owner can not be a member");
        require(msg.sender == owner, "Only owner can add members");
        require(
            isShipper[_memberAddress] == false &&
                isTransporter[_memberAddress] == false &&
                isConsigner[_memberAddress] == false,
            "Member exist"
        );

        Member memory memberInstance = Member(
            _memberName,
            _memberAddress,
            _memberType
        );
        members.push(memberInstance);

        getMember[_memberAddress] = memberInstance;

        if (_memberType == MemberType.Shipper) {
            isShipper[_memberAddress] = true;
        } else if (_memberType == MemberType.Transporter) {
            isTransporter[_memberAddress] = true;
        } else {
            isConsigner[_memberAddress] = true;
        }
    }

    function createCargo(
        uint256 _price,
        string memory _productInfo,
        address _transporter,
        address _consigner
    ) public {
        address _shipper = msg.sender;

        require(
            _transporter != address(0) || _consigner != address(0),
            "Zero address not allowed"
        );

        require(
            getMember[msg.sender].memberType == MemberType.Shipper,
            "Only Shipper can create cargo"
        );

        require(isShipper[_shipper] == true, "Shipper not allowed");
        require(isTransporter[_transporter] == true, "Transporter not allowed");
        require(isConsigner[_consigner] == true, "Consigner not allowed");

        bytes4 pId = bytes4(
            keccak256(abi.encodePacked(block.timestamp, _productInfo))
        );
        Product memory productInstance = Product(
            pId,
            _price,
            _productInfo,
            ProductState.Packed,
            MemberType.Shipper,
            _shipper,
            payable(_shipper),
            _transporter,
            _consigner
        );

        allProducts.push(productInstance);
        productIds.push(pId);

        product[pId] = productInstance;
    }

    function signTransport(bytes4 _id) public {
        require(
            getMember[msg.sender].memberType == MemberType.Transporter,
            "Only Transporter can dispatch cargo"
        );
        require(
            product[_id].transporter == msg.sender,
            "you are not authorized to sign the transport"
        );
        require(
            product[_id].state == ProductState.Packed,
            "Item needs to be in Packed State"
        );

        product[_id].state = ProductState.Dispatched;
        product[_id].lastUpdateBy = MemberType.Transporter;
        product[_id].addressOfSigner = msg.sender;
    }

    function signDelivered(bytes4 _id) public payable {
        require(
            getMember[msg.sender].memberType == MemberType.Consigner,
            "Only Consigner can recieve cargo"
        );
        require(
            product[_id].consigner == msg.sender,
            "you are not authorized to sign the delivery"
        );

        require(
            product[_id].state == ProductState.Dispatched,
            "Item needs to be in Dispatched State"
        );

        // product[_id].state = ProductState.Delivered;
        // product[_id].lastUpdateBy = MemberType.Consigner;
        // product[_id].addressOfSigner = msg.sender;

        (bool success, ) = product[_id].shipper.call{
            value: product[_id].price * 10 ** 18
        }("");
        require(success, "Payment to shipper failed");

        product[_id].state = ProductState.Delivered;
        product[_id].lastUpdateBy = MemberType.Consigner;
        product[_id].addressOfSigner = msg.sender;
    }

    function getProduct(bytes4 _id) public view returns (Product memory) {
        return product[_id];
    }

    function getMemberInfo(
        address _memberAddress
    ) public view returns (Member memory) {
        return getMember[_memberAddress];
    }

    function getProductIds() public view returns (bytes4[] memory) {
        return productIds;
    }
}
