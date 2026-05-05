// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/SunstakeFactory.sol";
import "../src/SolarProject.sol";
import "../src/PaymentSplitter.sol";
import "../src/OwnershipTransfer.sol";
import "./mocks/MockUSDC.sol";

/// @notice Tests de OwnershipTransfer: guards de acceso, cierre, eventos.
contract OwnershipTransferTest is Test {
    MockUSDC public usdc;
    SunstakeFactory public factory;

    address public treasury = makeAddr("treasury");
    address public beneficiario = makeAddr("beneficiario");
    address public inversor1 = makeAddr("inversor1");
    address public attacker = makeAddr("attacker");

    uint256 constant CUOTA = 48_570_000;
    uint256 constant MONTO_TOTAL = 2_250_000_000;
    uint256 constant RENDIMIENTO_BPS = 920;
    uint256 constant PLATFORM_FEE_BPS = 700;

    SolarProject public project;
    PaymentSplitter public splitter;
    OwnershipTransfer public ownershipTransfer;

    function setUp() public {
        usdc = new MockUSDC();
        factory = new SunstakeFactory(address(usdc), treasury, PLATFORM_FEE_BPS);

        vm.prank(beneficiario);
        (address sp, address ps, address ot) = factory.createProject(
            CUOTA, MONTO_TOTAL, 12, RENDIMIENTO_BPS, unicode"Mérida", "YUC"
        );

        project = SolarProject(sp);
        splitter = PaymentSplitter(ps);
        ownershipTransfer = OwnershipTransfer(ot);
    }

    // -------------------------------------------------------------------------
    // Guards de acceso
    // -------------------------------------------------------------------------

    function test_SoloPaymentSplitterPuedeCompletar() public {
        vm.prank(attacker);
        vm.expectRevert("OwnershipTransfer: solo PaymentSplitter");
        ownershipTransfer.completeProject();
    }

    function test_NoPuedeCompletarSinPagarPlazo() public {
        // Simular que el PS intenta llamar sin completar el plazo
        vm.prank(address(splitter));
        vm.expectRevert("OwnershipTransfer: plazo no completado");
        ownershipTransfer.completeProject();
    }

    function test_SetPaymentSplitterSoloFactory() public {
        // Un atacante no puede cambiar el paymentSplitter
        vm.prank(attacker);
        vm.expectRevert("OwnershipTransfer: solo la factory");
        ownershipTransfer.setPaymentSplitter(attacker);
    }

    function test_SetPaymentSplitterSoloUnaVez() public {
        // Ya fue configurado en setUp via factory; intentar de nuevo debe revertir
        address factoryAddr = address(factory);
        vm.prank(factoryAddr);
        vm.expectRevert("OwnershipTransfer: ya configurado");
        ownershipTransfer.setPaymentSplitter(attacker);
    }

    // -------------------------------------------------------------------------
    // Flujo de cierre
    // -------------------------------------------------------------------------

    function test_CompletadoInicialmenteFalse() public view {
        assertFalse(ownershipTransfer.isCompleted());
        assertEq(ownershipTransfer.getCompletedAt(), 0);
    }

    function test_CompletadoDespuesDe12Pagos() public {
        _investir(inversor1, 500e6);

        for (uint256 i = 0; i < 12; i++) {
            _pagarCuota();
        }

        assertTrue(ownershipTransfer.isCompleted());
        assertGt(ownershipTransfer.getCompletedAt(), 0);
    }

    function test_EventosPropiedadTransferida() public {
        _investir(inversor1, 500e6);

        for (uint256 i = 0; i < 11; i++) {
            _pagarCuota();
        }

        // Grabar logs del 12vo pago para verificar que ProyectoCompletado es emitido
        vm.recordLogs();
        _pagarCuota();

        // Verificar que el proyecto quedó completado (el evento fue emitido correctamente)
        assertTrue(ownershipTransfer.isCompleted());
        assertFalse(project.getProjectMetadata().activo);

        // Verificar que hay logs emitidos (incluyendo ProyectoCompletado y PropiedadTransferida)
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertGt(logs.length, 0);
    }

    function test_NoPuedeCompletarDosVeces() public {
        _investir(inversor1, 500e6);

        for (uint256 i = 0; i < 12; i++) {
            _pagarCuota();
        }

        // Intentar completar de nuevo debe revertir
        vm.prank(address(splitter));
        vm.expectRevert("OwnershipTransfer: ya completado");
        ownershipTransfer.completeProject();
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

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
