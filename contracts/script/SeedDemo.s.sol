// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/SunstakeFactory.sol";
import "../src/SolarProject.sol";
import "../src/PaymentSplitter.sol";

/// @notice Puebla Base Sepolia con proyectos de demo para el hackathon.
///         Crea 3 proyectos realistas (Ana en GDL, María en MTY, Carlos en YUC)
///         con inversores simulados y 2 ciclos de pago mensual completados.
///
/// Requisitos:
///   - SunstakeFactory ya desplegada (FACTORY_ADDRESS en .env)
///   - Deployer debe tener USDC en Base Sepolia
///     Obtener USDC Sepolia: https://faucet.circle.com
///   - Deployer actúa como todos los beneficiarios e inversores para simplificar el demo
///
/// Uso:
///   forge script script/SeedDemo.s.sol --rpc-url base_sepolia \
///     --private-key $PRIVATE_KEY --broadcast -vvvv
contract SeedDemoScript is Script {
    // USDC en Base Sepolia
    IERC20 constant USDC = IERC20(0x036CbD53842c5426634e7929541eC2318f3dCF7e);

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        SunstakeFactory factory = SunstakeFactory(factoryAddress);

        console2.log("=== Sunstake Demo Seed ===");
        console2.log("Factory:", factoryAddress);
        console2.log("Deployer (actua como beneficiarios e inversores):", deployer);

        uint256 usdcBalance = USDC.balanceOf(deployer);
        console2.log("Balance USDC del deployer:", usdcBalance / 1e6, "USDC");
        require(usdcBalance >= 3_000e6, "Necesitas al menos 3,000 USDC en Base Sepolia");

        vm.startBroadcast(deployerKey);

        // -----------------------------------------------------------------------
        // Proyecto 1: Ana — Guadalajara, JAL — 36 meses
        // Cuota: $48.57 USDC/mes (~$850 MXN) | Panel 2kW | Rendimiento 9.2%
        // -----------------------------------------------------------------------
        (address sp1, address ps1,) = factory.createProject(
            48_570_000, // cuota: $48.57 USDC
            2_250_000_000, // total: $2,250 USDC
            36,
            920, // 9.2% rendimiento
            "Guadalajara",
            "JAL"
        );
        console2.log("\n[Proyecto 1] Guadalajara, JAL");
        console2.log("  SolarProject:", sp1);
        console2.log("  PaymentSplitter:", ps1);

        // Inversores simulados para Proyecto 1
        // Inversor A invierte $500 USDC (~22.2% del proyecto)
        USDC.approve(sp1, 500e6);
        SolarProject(sp1).invest(500e6);
        console2.log("  Inversion A: $500 USDC");

        // Inversor B invierte $750 USDC (~33.3%)
        USDC.approve(sp1, 750e6);
        SolarProject(sp1).invest(750e6);
        console2.log("  Inversion B: $750 USDC");

        // Simular 2 pagos mensuales del beneficiario
        _pagarCuota(ps1, 48_570_000);
        _pagarCuota(ps1, 48_570_000);
        console2.log("  Pagos completados: 2/36");

        // -----------------------------------------------------------------------
        // Proyecto 2: Maria — Monterrey, NL — 24 meses
        // Cuota: $75 USDC/mes | Panel 1.5kW | Rendimiento 8.7%
        // -----------------------------------------------------------------------
        (address sp2, address ps2,) = factory.createProject(
            75_000_000, // cuota: $75 USDC
            1_800_000_000, // total: $1,800 USDC
            24,
            870, // 8.7%
            "Monterrey",
            "NL"
        );
        console2.log("\n[Proyecto 2] Monterrey, NL");
        console2.log("  SolarProject:", sp2);
        console2.log("  PaymentSplitter:", ps2);

        // Inversores para Proyecto 2
        USDC.approve(sp2, 300e6);
        SolarProject(sp2).invest(300e6);
        console2.log("  Inversion A: $300 USDC");

        // 2 pagos mensuales
        _pagarCuota(ps2, 75_000_000);
        _pagarCuota(ps2, 75_000_000);
        console2.log("  Pagos completados: 2/24");

        // -----------------------------------------------------------------------
        // Proyecto 3: Carlos — Merida, YUC — 36 meses
        // Alta radiacion solar (ciudad con mas sol en Mexico) | Rendimiento 10.1%
        // -----------------------------------------------------------------------
        (address sp3, address ps3,) = factory.createProject(
            77_780_000, // cuota: ~$77.78 USDC
            2_800_000_000, // total: $2,800 USDC
            36,
            1010, // 10.1%
            unicode"Mérida",
            "YUC"
        );
        console2.log(unicode"\n[Proyecto 3] Mérida, YUC");
        console2.log("  SolarProject:", sp3);
        console2.log("  PaymentSplitter:", ps3);

        // Inversores para Proyecto 3
        USDC.approve(sp3, 200e6);
        SolarProject(sp3).invest(200e6);
        console2.log("  Inversion A: $200 USDC");

        // Sin pagos aún (proyecto reciente para el demo)
        console2.log("  Pagos completados: 0/36 (proyecto nuevo)");

        vm.stopBroadcast();

        // -----------------------------------------------------------------------
        // Resumen final para la app iOS
        // -----------------------------------------------------------------------
        console2.log("\n=== ADDRESSES PARA LA APP iOS ===");
        console2.log("Agrega estas constantes en BlockchainService.swift:");
        console2.log("");
        console2.log("static let factoryAddress =", vm.toString(factoryAddress));
        console2.log("");
        console2.log("Proyectos de demo en Base Sepolia:");
        console2.log("  [GDL 36m 9.2%%]", sp1);
        console2.log("  [MTY 24m 8.7%%]", sp2);
        console2.log(unicode"  [YUC 36m 10.1%%]", sp3);
        console2.log("");
        console2.log("Verifica en: https://sepolia.basescan.org");
    }

    function _pagarCuota(address paymentSplitter, uint256 cuota) internal {
        USDC.approve(paymentSplitter, cuota);
        PaymentSplitter(paymentSplitter).payMonthly();
    }
}
