// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/SunstakeFactory.sol";
import "../src/SolarProject.sol";
import "../src/PaymentSplitter.sol";
import "../src/OwnershipTransfer.sol";
import "./mocks/MockUSDC.sol";

/// @notice Tests de PaymentSplitter: pago mensual, distribución pro-rata, fee de plataforma.
contract PaymentSplitterTest is Test {
    MockUSDC public usdc;
    SunstakeFactory public factory;

    address public treasury = makeAddr("treasury");
    address public beneficiario = makeAddr("beneficiario");
    address public inversor1 = makeAddr("inversor1");
    address public inversor2 = makeAddr("inversor2");

    uint256 constant CUOTA = 48_570_000; // $48.57 USDC
    uint256 constant MONTO_TOTAL = 2_250_000_000; // $2,250 USDC
    uint256 constant PLAZO = 3; // 3 meses para tests rápidos (factory valida 12/24/36)
    uint256 constant RENDIMIENTO_BPS = 920;
    uint256 constant PLATFORM_FEE_BPS = 700; // 7%

    SolarProject public project;
    PaymentSplitter public splitter;
    OwnershipTransfer public ownershipTransfer;

    function setUp() public {
        usdc = new MockUSDC();
        factory = new SunstakeFactory(address(usdc), treasury, PLATFORM_FEE_BPS);

        vm.prank(beneficiario);
        (address sp, address ps, address ot) = factory.createProject(
            CUOTA, MONTO_TOTAL, 12, RENDIMIENTO_BPS, "Monterrey", "NL"
        );

        project = SolarProject(sp);
        splitter = PaymentSplitter(ps);
        ownershipTransfer = OwnershipTransfer(ot);
    }

    // -------------------------------------------------------------------------
    // Tests de pago mensual
    // -------------------------------------------------------------------------

    function test_PagoMensualIncrementaMeses() public {
        _investirAmbos();
        _pagarCuota();

        SolarProject.Metadata memory meta = project.getProjectMetadata();
        assertEq(meta.mesesPagados, 1);
    }

    function test_FeeVaAlTreasury() public {
        _investirAmbos();
        uint256 balancePrevio = usdc.balanceOf(treasury);
        _pagarCuota();

        uint256 feeEsperado = (CUOTA * PLATFORM_FEE_BPS) / 10_000;
        assertEq(usdc.balanceOf(treasury), balancePrevio + feeEsperado);
    }

    function test_YieldDistribuidoProRata() public {
        // Dentro del MONTO_TOTAL ($2,250 USDC): inversor1 = 25%, inversor2 = 75%
        uint256 montoI1 = 562_500_000; // 562.5 USDC = 25%
        uint256 montoI2 = 1_687_500_000; // 1687.5 USDC = 75%
        _investir(inversor1, montoI1);
        _investir(inversor2, montoI2);
        uint256 totalInvertido = montoI1 + montoI2;

        uint256 balI1antes = usdc.balanceOf(inversor1);
        uint256 balI2antes = usdc.balanceOf(inversor2);

        _pagarCuota();

        uint256 yieldPool = CUOTA - (CUOTA * PLATFORM_FEE_BPS) / 10_000;
        uint256 shareI1 = (montoI1 * yieldPool) / totalInvertido;

        assertApproxEqAbs(usdc.balanceOf(inversor1) - balI1antes, shareI1, 1);
        assertApproxEqAbs(
            usdc.balanceOf(inversor2) - balI2antes, yieldPool - shareI1, 1
        );
    }

    function test_SoloBeneficiarioPuedePagar() public {
        _investirAmbos();
        usdc.mint(inversor1, CUOTA);

        vm.startPrank(inversor1);
        usdc.approve(address(splitter), CUOTA);
        vm.expectRevert("PaymentSplitter: solo el beneficiario");
        splitter.payMonthly();
        vm.stopPrank();
    }

    function test_EstimacionYieldMensual() public {
        uint256 montoI1 = 562_500_000; // 25%
        uint256 montoI2 = 1_687_500_000; // 75%
        _investir(inversor1, montoI1);
        _investir(inversor2, montoI2);
        uint256 totalInvertido = montoI1 + montoI2;

        uint256 estimado = splitter.estimateMonthlyYield(inversor1);
        uint256 yieldPool = CUOTA - (CUOTA * PLATFORM_FEE_BPS) / 10_000;
        uint256 esperado = (montoI1 * yieldPool) / totalInvertido;

        assertApproxEqAbs(estimado, esperado, 1);
    }

    function test_GetPlatformFee() public view {
        assertEq(splitter.getPlatformFee(), PLATFORM_FEE_BPS);
    }

    // -------------------------------------------------------------------------
    // Tests de cierre del proyecto
    // -------------------------------------------------------------------------

    function test_FlujoCompleto_12Meses() public {
        _investirAmbos();

        // Pagar 12 cuotas completas
        for (uint256 i = 0; i < 12; i++) {
            _pagarCuota();
        }

        // El proyecto debe estar completado
        assertTrue(ownershipTransfer.isCompleted());
        assertFalse(project.getProjectMetadata().activo);
        assertEq(project.totalSupply(), 0);
    }

    function test_TokensQuemadosAlCompletar() public {
        _investir(inversor1, 500e6);
        _investir(inversor2, 800e6);

        for (uint256 i = 0; i < 12; i++) {
            _pagarCuota();
        }

        assertEq(project.balanceOf(inversor1, project.TOKEN_ID()), 0);
        assertEq(project.balanceOf(inversor2, project.TOKEN_ID()), 0);
        assertEq(project.investorCount(), 0);
    }

    function test_NoPuedePagarDespuesDeCompletar() public {
        _investirAmbos();

        for (uint256 i = 0; i < 12; i++) {
            _pagarCuota();
        }

        // El 13er pago debe revertir — el proyecto ya está inactivo (activo = false)
        usdc.mint(beneficiario, CUOTA);
        vm.startPrank(beneficiario);
        usdc.approve(address(splitter), CUOTA);
        vm.expectRevert("PaymentSplitter: proyecto inactivo");
        splitter.payMonthly();
        vm.stopPrank();
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    function _investirAmbos() internal {
        _investir(inversor1, 1_125_000_000); // $1,125 USDC = 50%
        _investir(inversor2, 1_125_000_000); // $1,125 USDC = 50%
    }

    function _investir(address inversor, uint256 monto) internal {
        usdc.mint(inversor, monto);
        vm.startPrank(inversor);
        usdc.approve(address(project), monto);
        project.invest(monto);
        vm.stopPrank();
    }

    function _pagarCuota() internal {
        usdc.mint(beneficiario, CUOTA);
        vm.startPrank(beneficiario);
        usdc.approve(address(splitter), CUOTA);
        splitter.payMonthly();
        vm.stopPrank();
    }
}
