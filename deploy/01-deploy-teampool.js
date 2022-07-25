const { network, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

const PAYMENT = ethers.utils.parseEther("0.1")

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    let entranceFee, priceFeedAddress, payment, linkToken, oracle, jobId

    entranceFee = networkConfig[chainId]["entranceFee"]
    priceFeedAddress = networkConfig[chainId]["priceFeed"]
    payment = networkConfig[chainId]["payment"]
    linkToken = networkConfig[chainId]["linkToken"]
    oracle = networkConfig[chainId]["oracle"]
    jobId = networkConfig[chainId]["jobId"]

    const args = [entranceFee, priceFeedAddress, link, oracle]

    const teamPool = await deploy("TeamPool", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(teamPool.address, args)

        log("------------------------------------------")
    }
}
