// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Script} from "../lib/forge-std/src/Script.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Unitroller} from "../contracts/Unitroller.sol";
import {ComptrollerG7} from "../contracts/ComptrollerG7.sol";
import {Comptroller} from "../contracts/Comptroller.sol";
import {SimplePriceOracle} from "../contracts/SimplePriceOracle.sol";
import {WhitePaperInterestRateModel} from "../contracts/WhitePaperInterestRateModel.sol";
import {CToken} from "../contracts/CToken.sol";
import {CErc20Delegator} from "../contracts/CErc20Delegator.sol";
import {CErc20Delegate} from "../contracts/CErc20Delegate.sol";
import {InterestRateModel} from "../contracts/InterestRateModel.sol";
import {ComptrollerInterface} from "../contracts/ComptrollerInterface.sol";

// 撰寫一個 Foundry 的 Script，該 Script 要能夠部署一個 CErc20Delegator(CErc20Delegator.sol，以下簡稱 cERC20)，一個 Unitroller(Unitroller.sol) 以及他們的 Implementation 合約和合約初始化時相關必要合約。請遵循以下細節：

// cERC20 的 decimals 皆為 18
// 自行部署一個 cERC20 的 underlying ERC20 token，decimals 為 18
// 使用 SimplePriceOracle 作為 Oracle
// 使用 WhitePaperInterestRateModel 作為利率模型，利率模型合約中的借貸利率設定為 0%
// 初始 exchangeRate 為 1:1

contract DeployScript is Script {
    SimplePriceOracle priceOracle;

    Unitroller unitroller;
    Comptroller comptroller;

    ERC20 underlying;
    CErc20Delegate cMyTokenDelegate;
    CErc20Delegator cToken;

    function run() external {
        vm.startBroadcast(0x2eaf5652603b370dac51f5633adbc43106e32ff075451be14bcdaf1b2999d91b);

        // 1. PriceOracle
        priceOracle = new SimplePriceOracle();

        //  2. unitroller comptroller
        unitroller = new Unitroller();
        comptroller = new Comptroller();
        comptroller._setPriceOracle(priceOracle);
        unitroller._setPendingImplementation(address(comptroller));

        // 3. InterestRateModel
        // 使用 WhitePaperInterestRateModel 作為利率模型，利率模型合約中的借貸利率設定為 0%
        WhitePaperInterestRateModel interestRateModel = new WhitePaperInterestRateModel(0, 0);

        // 4. cToken
        underlying = new ERC20("My Token", "MTK");
        cMyTokenDelegate = new CErc20Delegate();

        cToken = new CErc20Delegator(
            address(underlying),
            comptroller,
            interestRateModel,
            1e18, // initialExchangeRateMantissa_
            "cMy Token",
            "cMTK",
            18,
            payable(msg.sender), // admin_
            address(cMyTokenDelegate), // implementation_
            "" // becomeImplementationData
        );

        vm.stopBroadcast();
    }
}
