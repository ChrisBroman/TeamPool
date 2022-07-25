const { ethers } = require("hardhat")

const networkConfig = {
    42: {
        name: "kovan",
        payment: ethers.utils.parseEther("0.1"),
        entranceFee: ethers.utils.parseEther("0.01324904"),
        priceFeed: "0x9326BFA02ADD2366b30bacB125260Af641031331",
        linkToken: "0xa36085F69e2889c224210F603D836748e7dC0088",
        oracle: "0xFb0951bA1929336D2F621Cc0f0928D89A91D508f",
        jobId: "0x3662303964333762323834663436353562623531306634393465646331313166",
    },
    31337: {
        name: "localhost",
    },
    137: {
        name: "polygon",
        payment: ethers.utils.parseEther("0.1"),
        entranceFee: ethers.utils.parseEther("0.01324904"),
        priceFeed: "0xAB594600376Ec9fD91F8e885dADF0CE036862dE0",
        linkToken: "0xb0897686c545045aFc77CF20eC7A532E3120E0F1",
        oracle: "0x5fA5556cA9b39886eD448A2ae2A8A4a1f2B3Bbba",
        jobId: "0x3233663930383335623264313463663938383339386337333833306139323837",
    },
}

const developmentChains = ["hardhat", "localhost"]

module.exports = {
    networkConfig,
    developmentChains,
}
