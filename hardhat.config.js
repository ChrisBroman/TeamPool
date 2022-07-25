require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY
const PRIVATE_KEY = process.env.PRIVATE_KEY
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY
const POLYGON_MAIN_RPC_URL = process.env.POLYGON_MAIN_RPC_URL
const POLYGON_MAIN_LINK_TOKEN_ADDRESS = process.env.POLYGON_MAIN_LINK_TOKEN_ADDRESS
const POLYGON_MAIN_OPERATOR_ADDRESS = process.env.POLYGON_MAIN_OPERATOR_ADDRESS
const POLYGON_MAIN_JOB_ID = process.env.POLYGON_MAIN_JOB_ID
const POLYGON_PAYMENT = process.env.POLYGON_PAYMENT
const KOVAN_RPC_URL = process.env.KOVAN_RPC_URL

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
        },
        polygon: {
            chainId: 137,
            url: POLYGON_MAIN_RPC_URL,
        },
        kovan: {
            chainId: 42,
            url: KOVAN_RPC_URL,
            blockConfirmations: 6,
            accounts: [PRIVATE_KEY],
        },
    },
    etherscan: {
        apiKey: ETHERSCAN_API_KEY,
    },
    solidity: {
        compilers: [
            { version: "0.8.7" },
            { version: "0.8.8" },
            { version: "0.8.0" },
            { version: "0.8.13" },
        ],
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
        player: {
            default: 1,
        },
    },
}
