// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/SunstakeFactory.sol";

/// @notice Despliega SunstakeFactory en Base Sepolia (o Mainnet).
///         La Factory es el único contrato que se despliega manualmente;
///         SolarProject, PaymentSplitter y OwnershipTransfer los crea la Factory.
///
/// Uso:
///   # Cargar variables
///   cp .env.example .env && nano .env
///
///   # Deploy en Base Sepolia (testnet)
///   forge script script/Deploy.s.sol --rpc-url base_sepolia \
///     --private-key $PRIVATE_KEY --broadcast --verify -vvvv
///
///   # Deploy en Base Mainnet
///   forge script script/Deploy.s.sol --rpc-url base_mainnet \
///     --private-key $PRIVATE_KEY --broadcast --verify -vvvv
contract DeployScript is Script {
    // USDC de pruebas en Base Sepolia: TestnetERC20 (6 decimales).
    // Faucet con mint generoso: https://staging.aave.com/faucet (selecciona Base Sepolia).
    address constant USDC_SEPOLIA = 0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f;
    // USDC en Base Mainnet (oficial de Circle, 6 decimales).
    address constant USDC_MAINNET = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    // Fee de plataforma: 7% = 700 bps
    uint256 constant PLATFORM_FEE_BPS = 700;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Leer la dirección de la treasury de Sunstake del env
        // Si no está definida, usar el deployer como treasury (solo para testnet)
        address treasury;
        try vm.envAddress("SUNSTAKE_TREASURY") returns (address t) {
            treasury = t;
        } catch {
            treasury = deployer;
            console2.log("SUNSTAKE_TREASURY no definida, usando deployer como treasury");
        }

        // Determinar si estamos en Sepolia o Mainnet
        bool isSepolia = block.chainid == 84532;
        address usdcAddress = isSepolia ? USDC_SEPOLIA : USDC_MAINNET;

        console2.log("=== Sunstake Factory Deploy ===");
        console2.log("Chain ID:", block.chainid);
        console2.log("Network:", isSepolia ? "Base Sepolia (testnet)" : "Base Mainnet");
        console2.log("Deployer:", deployer);
        console2.log("Treasury:", treasury);
        console2.log("USDC:", usdcAddress);
        console2.log("Platform fee (bps):", PLATFORM_FEE_BPS);
        console2.log("Platform fee (%%):", PLATFORM_FEE_BPS / 100);

        vm.startBroadcast(deployerPrivateKey);

        SunstakeFactory factory =
            new SunstakeFactory(usdcAddress, treasury, PLATFORM_FEE_BPS);

        vm.stopBroadcast();

        console2.log("\n=== Deploy exitoso ===");
        console2.log("SunstakeFactory:", address(factory));
        console2.log(
            "\nVerifica en Basescan:",
            isSepolia
                ? string.concat(
                    "https://sepolia.basescan.org/address/", vm.toString(address(factory))
                )
                : string.concat("https://basescan.org/address/", vm.toString(address(factory)))
        );
        console2.log(
            "\nCOMPARTE esta address con el equipo de iOS para hardcodearla como FACTORY_ADDRESS"
        );
    }
}
