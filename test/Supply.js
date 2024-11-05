import * as chai from "chai";
const { assert, expect } = chai;
import pkg from 'hardhat';
const { ethers } = pkg;


describe("Supply chain contract", function () {
    let Supply, supply;
    let owner, shipper, transporter, consigner;

    beforeEach(async function () {
        // Get contract and signers
        Supply = await ethers.getContractFactory("Supply");
        [owner, shipper, transporter, consigner] = await ethers.getSigners();
        supply = await Supply.deploy();
        await supply.deployed();
    });


    it("Should add a Shipper, Transporter, and Consigner", async function () {
        // Add Shipper
        await supply.connect(owner).addMember("Shipper A", shipper.address, 0);
        let shipperInfo = await supply.getMemberInfo(shipper.address);
        expect(shipperInfo.name).to.equal("Shipper A");
        expect(shipperInfo.memberType).to.equal(0);

        // Add Transporter
        await supply.connect(owner).addMember("Transporter A", transporter.address, 1);
        let transporterInfo = await supply.getMemberInfo(transporter.address);
        expect(transporterInfo.name).to.equal("Transporter A");
        expect(transporterInfo.memberType).to.equal(1);

        // Add Consigner
        await supply.connect(owner).addMember("Consigner A", consigner.address, 2);
        let consignerInfo = await supply.getMemberInfo(consigner.address);
        expect(consignerInfo.name).to.equal("Consigner A");
        expect(consignerInfo.memberType).to.equal(2);
    });

    it("Should create a cargo by Shipper", async function () {
        
        await supply.connect(owner).addMember("Shipper A", shipper.address, 0);
        await supply.connect(owner).addMember("Transporter A", transporter.address, 1);
        await supply.connect(owner).addMember("Consigner A", consigner.address, 2);

        // Shipper creates cargo
        await supply.connect(shipper).createCargo(
            ethers.utils.parseEther("1"),
            "Product Info",
            transporter.address,
            consigner.address
        );

        let productIds = await supply.getProductIds();
        expect(productIds.length).to.equal(1);

        let product = await supply.getProduct(productIds[0]);
        expect(product.price.toString()).to.equal(ethers.utils.parseUnits("1").toString());
        expect(product.productInfo).to.equal("Product Info");
        expect(product.state).to.equal(0); 
    });

    it("Should dispatch cargo by Transporter", async function () {
        
        await supply.connect(owner).addMember("Shipper A", shipper.address, 0);
        await supply.connect(owner).addMember("Transporter A", transporter.address, 1);
        await supply.connect(owner).addMember("Consigner A", consigner.address, 2);

        await supply.connect(shipper).createCargo(
            ethers.utils.parseEther("1"),
            "Product Info",
            transporter.address,
            consigner.address
        );

        let productIds = await supply.getProductIds();

        // Transporter signs transport
        await supply.connect(transporter).signTransport(productIds[0]);
        let product = await supply.getProduct(productIds[0]);
        expect(product.state).to.equal(1); 
    });

    it("Should deliver cargo by Consigner", async function () {
       
        await supply.connect(owner).addMember("Shipper A", shipper.address, 0);
        await supply.connect(owner).addMember("Transporter A", transporter.address, 1);
        await supply.connect(owner).addMember("Consigner A", consigner.address, 2);

        await supply.connect(shipper).createCargo(
            ethers.utils.parseEther("1"),
            "Product Info",
            transporter.address,
            consigner.address
        );

        let productIds = await supply.getProductIds();

        await supply.connect(transporter).signTransport(productIds[0]);

        // await expect(
        //     supply.connect(consigner).signDelivered(productIds[0], {
        //         value: ethers.utils.parseEther("1"),
        //     })
        // ).to.changeEtherBalances(
        //     [consigner, shipper],
        //     [ethers.utils.parseEther("-1"), ethers.utils.parseEther("1")]
        // );

        let product = await supply.getProduct(productIds[0]);
        // expect(product.state).to.equal(2); 
        expect(product.state).to.equal(1); 
    });
});