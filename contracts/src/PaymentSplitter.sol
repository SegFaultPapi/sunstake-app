// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SolarProject.sol";
import "./OwnershipTransfer.sol";

/// @title PaymentSplitter
/// @notice Recibe el pago mensual del beneficiario en USDC y distribuye:
///         - 92-95% pro-rata a cada inversor según su balance de tokens
///         - 5-8% a la wallet de Sunstake como fee de plataforma
///         Al completar el plazo, activa OwnershipTransfer.
contract PaymentSplitter is ReentrancyGuard {
    // -------------------------------------------------------------------------
    // Estado
    // -------------------------------------------------------------------------

    IERC20 public immutable usdc;
    SolarProject public immutable project;
    OwnershipTransfer public immutable ownershipTransfer;

    address public immutable sunstakeTreasury;
    uint256 public immutable platformFeeBps; // e.g. 700 = 7%

    /// @notice Historial de pagos recibidos (para auditoría on-chain)
    uint256 public totalRecibido;
    uint256 public totalDistribuido;

    // -------------------------------------------------------------------------
    // Eventos
    // -------------------------------------------------------------------------

    event PagoRecibido(
        address indexed beneficiario, uint256 monto, uint256 mes, uint256 timestamp
    );
    event YieldDistribuido(
        address indexed investor, uint256 monto, uint256 mes, uint256 timestamp
    );
    event FeeTransferido(address indexed treasury, uint256 monto, uint256 mes);
    event ProyectoCompletado(address indexed project, uint256 timestamp);

    // -------------------------------------------------------------------------
    // Modificadores
    // -------------------------------------------------------------------------

    modifier soloBeneficiario() {
        SolarProject.Metadata memory meta = project.getProjectMetadata();
        require(msg.sender == meta.beneficiario, "PaymentSplitter: solo el beneficiario");
        _;
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    constructor(
        address _project,
        address _ownershipTransfer,
        address _usdc,
        address _sunstakeTreasury,
        uint256 _platformFeeBps
    ) {
        require(_project != address(0), "PaymentSplitter: project zero");
        require(_ownershipTransfer != address(0), "PaymentSplitter: ownershipTransfer zero");
        require(_usdc != address(0), "PaymentSplitter: usdc zero");
        require(_sunstakeTreasury != address(0), "PaymentSplitter: treasury zero");
        require(_platformFeeBps >= 500 && _platformFeeBps <= 800, "PaymentSplitter: fee fuera de rango 5-8%");

        project = SolarProject(_project);
        ownershipTransfer = OwnershipTransfer(_ownershipTransfer);
        usdc = IERC20(_usdc);
        sunstakeTreasury = _sunstakeTreasury;
        platformFeeBps = _platformFeeBps;
    }

    // -------------------------------------------------------------------------
    // Flujo de pago mensual
    // -------------------------------------------------------------------------

    /// @notice El beneficiario paga su cuota mensual.
    ///         Requiere approve() previo de USDC (>= cuotaMensualUSDC) a esta dirección.
    ///         HCAI: Confirmación biométrica en iOS antes de llamar esta función.
    function payMonthly() external nonReentrant soloBeneficiario {
        SolarProject.Metadata memory meta = project.getProjectMetadata();
        require(meta.activo, "PaymentSplitter: proyecto inactivo");
        require(meta.mesesPagados < meta.plazoMeses, "PaymentSplitter: plazo ya completado");

        uint256 cuota = meta.cuotaMensualUSDC;

        require(
            usdc.transferFrom(msg.sender, address(this), cuota),
            "PaymentSplitter: transferencia USDC fallida"
        );

        totalRecibido += cuota;
        uint256 mesActual = meta.mesesPagados + 1;

        emit PagoRecibido(msg.sender, cuota, mesActual, block.timestamp);

        // 1. Calcular y transferir fee de plataforma
        uint256 fee = (cuota * platformFeeBps) / 10_000;
        uint256 yieldPool = cuota - fee;

        if (fee > 0) {
            require(usdc.transfer(sunstakeTreasury, fee), "PaymentSplitter: fee transfer fallido");
            emit FeeTransferido(sunstakeTreasury, fee, mesActual);
        }

        // 2. Distribuir yield pro-rata a todos los inversores
        _distributeYield(yieldPool, mesActual);

        totalDistribuido += yieldPool;

        // 3. Registrar el mes pagado en SolarProject
        project.incrementMesesPagados();

        // 4. Si se completó el plazo, activar OwnershipTransfer
        if (mesActual == meta.plazoMeses) {
            emit ProyectoCompletado(address(project), block.timestamp);
            ownershipTransfer.completeProject();
        }
    }

    // -------------------------------------------------------------------------
    // Distribución interna
    // -------------------------------------------------------------------------

    /// @notice Distribuye `amount` USDC entre todos los inversores pro-rata a sus tokens.
    ///         Gas aceptable para el demo (3-10 inversores ≈ $0.001 USD en Base).
    function _distributeYield(uint256 amount, uint256 mes) internal {
        uint256 supply = project.totalSupply();
        if (supply == 0 || amount == 0) return;

        address[] memory investors = project.getInvestors();
        uint256 distributed = 0;

        for (uint256 i = 0; i < investors.length; i++) {
            address investor = investors[i];
            uint256 balance = project.balanceOf(investor, project.TOKEN_ID());
            if (balance == 0) continue;

            uint256 share;
            if (i == investors.length - 1) {
                // El último inversor recibe el residuo para evitar pérdida por redondeo
                share = amount - distributed;
            } else {
                share = (balance * amount) / supply;
            }

            if (share > 0) {
                require(usdc.transfer(investor, share), "PaymentSplitter: yield transfer fallido");
                distributed += share;
                emit YieldDistribuido(investor, share, mes, block.timestamp);
            }
        }
    }

    // -------------------------------------------------------------------------
    // Vistas
    // -------------------------------------------------------------------------

    /// @notice Fee de plataforma configurado (5-8%)
    function getPlatformFee() external view returns (uint256) {
        return platformFeeBps;
    }

    /// @notice Estimación del yield mensual para un inversor dado su balance
    function estimateMonthlyYield(address investor) external view returns (uint256) {
        SolarProject.Metadata memory meta = project.getProjectMetadata();
        uint256 supply = project.totalSupply();
        if (supply == 0) return 0;

        uint256 balance = project.balanceOf(investor, project.TOKEN_ID());
        uint256 yieldPool = (meta.cuotaMensualUSDC * (10_000 - platformFeeBps)) / 10_000;
        return (balance * yieldPool) / supply;
    }
}
