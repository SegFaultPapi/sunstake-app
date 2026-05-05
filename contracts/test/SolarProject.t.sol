// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/SunstakeFactory.sol";
import "../src/SolarProject.sol";
import "../src/PaymentSplitter.sol";
import "../src/OwnershipTransfer.sol";
import "./mocks/MockUSDC.sol";

/// @notice Tests de SolarProject: deploy via factory, invest, guards de acceso.
contract SolarProjectTest is Test {
    MockUSDC public usdc;
    SunstakeFactory public factory;

    address public treasury = makeAddr("treasury");
    address public beneficiario = makeAddr("beneficiario");
    address public inversor1 = makeAddr("inversor1");
    address public inversor2 = makeAddr("inversor2");

    // Parámetros del proyecto de referencia (Ana, Guadalajara)
    uint256 constant CUOTA = 48_570_000; // $48.57 USDC (≈ $850 MXN / 17.5)
    uint256 constant MONTO_TOTAL = 2_250_000_000; // $2,250 USDC
    uint256 constant PLAZO = 36;
    uint256 constant RENDIMIENTO_BPS = 920; // 9.2%
    uint256 constant PLATFORM_FEE_BPS = 700; // 7%

    SolarProject public project;
    PaymentSplitter public splitter;
    OwnershipTransfer public ownershipTransfer;

    function setUp() public {
        usdc = new MockUSDC();
        factory = new SunstakeFactory(address(usdc), treasury, PLATFORM_FEE_BPS);

        vm.prank(beneficiario);
        (address sp, address ps, address ot) = factory.createProject(
            CUOTA, MONTO_TOTAL, PLAZO, RENDIMIENTO_BPS, "Guadalajara", "JAL"
        );

        project = SolarProject(sp);
        splitter = PaymentSplitter(ps);
        ownershipTransfer = OwnershipTransfer(ot);
    }

    // -------------------------------------------------------------------------
    // Tests de deploy y metadata
    // -------------------------------------------------------------------------

    function test_MetadataCorrecta() public view {
        SolarProject.Metadata memory meta = project.getProjectMetadata();

        assertEq(meta.beneficiario, beneficiario);
        assertEq(meta.cuotaMensualUSDC, CUOTA);
        assertEq(meta.montoTotalUSDC, MONTO_TOTAL);
        assertEq(meta.plazoMeses, PLAZO);
        assertEq(meta.rendimientoBps, RENDIMIENTO_BPS);
        assertEq(meta.mesesPagados, 0);
        assertTrue(meta.activo);
        assertEq(meta.ciudad, "Guadalajara");
        assertEq(meta.estado, "JAL");
        assertEq(meta.paymentSplitter, address(splitter));
        assertEq(meta.ownershipTransfer, address(ownershipTransfer));
    }

    function test_FactoryRegistraProyecto() public view {
        assertEq(factory.projectCount(), 1);
        address[] memory projects = factory.getProjects();
        assertEq(projects[0], address(project));

        (address ps, address ot, address bene) =
            factory.getProjectContracts(address(project));
        assertEq(ps, address(splitter));
        assertEq(ot, address(ownershipTransfer));
        assertEq(bene, beneficiario);
    }

    function test_PlazoInvalidoRevierte() public {
        vm.prank(beneficiario);
        vm.expectRevert("SolarProject: plazo invalido (12/24/36)");
        factory.createProject(CUOTA, MONTO_TOTAL, 18, RENDIMIENTO_BPS, "CDMX", "CDMX");
    }

    // -------------------------------------------------------------------------
    // Tests de invest()
    // -------------------------------------------------------------------------

    function test_InversorCompraTokens() public {
        uint256 inversion = 100e6; // $100 USDC
        usdc.mint(inversor1, inversion);

        vm.startPrank(inversor1);
        usdc.approve(address(project), inversion);
        project.invest(inversion);
        vm.stopPrank();

        assertEq(project.balanceOf(inversor1, project.TOKEN_ID()), inversion);
        assertEq(project.totalSupply(), inversion);
        assertEq(project.investorCount(), 1);
    }

    function test_DosInversoresRegistrados() public {
        _investir(inversor1, 200e6);
        _investir(inversor2, 300e6);

        assertEq(project.investorCount(), 2);
        assertEq(project.totalSupply(), 500e6);
    }

    function test_InversionMinimaRevierte() public {
        usdc.mint(inversor1, 1e6);
        vm.startPrank(inversor1);
        usdc.approve(address(project), 0.5e6);
        vm.expectRevert("SolarProject: inversion minima 1 USDC");
        project.invest(0.5e6);
        vm.stopPrank();
    }

    function test_InversionMaximaRevierte() public {
        uint256 exceso = 10_001e6;
        usdc.mint(inversor1, exceso);
        vm.startPrank(inversor1);
        usdc.approve(address(project), exceso);
        vm.expectRevert("SolarProject: inversion maxima 10,000 USDC");
        project.invest(exceso);
        vm.stopPrank();
    }

    function test_PorcentajeFinanciado() public {
        _investir(inversor1, MONTO_TOTAL / 2); // 50%

        uint256 pct = project.porcentajeFinanciadoBps();
        assertEq(pct, 5_000); // 50% = 5000 bps
    }

    function test_InversorShareProRata() public {
        // MONTO_TOTAL = 2_250 USDC; distribuir en 25%/75% dentro de ese límite
        _investir(inversor1, 562_500_000); // 562.5 USDC = 25%
        _investir(inversor2, 1_687_500_000); // 1687.5 USDC = 75%
        // Total: 2250 USDC = 100% del proyecto

        assertEq(project.getInvestorShare(inversor1), 2_500); // 25%
        assertEq(project.getInvestorShare(inversor2), 7_500); // 75%
    }

    // -------------------------------------------------------------------------
    // Guards de acceso
    // -------------------------------------------------------------------------

    function test_SoloPaymentSplitterPuedeIncrementarMeses() public {
        vm.prank(inversor1);
        vm.expectRevert("SolarProject: solo PaymentSplitter");
        project.incrementMesesPagados();
    }

    function test_SoloOwnershipTransferPuedeFinalizar() public {
        vm.prank(inversor1);
        vm.expectRevert("SolarProject: solo OwnershipTransfer");
        project.finalizeProject();
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
}
