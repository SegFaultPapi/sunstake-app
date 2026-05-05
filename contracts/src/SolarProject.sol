// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FractionToken.sol";

/// @title SolarProject
/// @notice Contrato principal de cada proyecto solar tokenizado en Sunstake.
///         Se despliega UNA VEZ por proyecto via SunstakeFactory.
///         Hereda FractionToken (ERC-1155): cada token representa $0.01 USDC de financiamiento.
///         Los inversores llaman invest() y reciben tokens proporcionales.
contract SolarProject is FractionToken, ReentrancyGuard {
    // -------------------------------------------------------------------------
    // Tipos
    // -------------------------------------------------------------------------

    struct Metadata {
        address beneficiario;
        uint256 cuotaMensualUSDC; // cuota mensual en USDC (6 decimales)
        uint256 montoTotalUSDC; // monto total a financiar en USDC
        uint256 plazoMeses; // 12, 24 o 36
        uint256 rendimientoBps; // rendimiento anual en bps (900 = 9%)
        uint256 mesesPagados; // incrementado por PaymentSplitter cada mes
        uint256 fechaInicio; // block.timestamp del deploy
        bool activo; // false cuando completeProject() es llamado
        string ciudad;
        string estado;
        address paymentSplitter; // dirección del PaymentSplitter asociado
        address ownershipTransfer; // dirección del OwnershipTransfer asociado
    }

    // -------------------------------------------------------------------------
    // Estado
    // -------------------------------------------------------------------------

    Metadata private _metadata;
    IERC20 public immutable usdc;

    /// @notice 1 token = 1 unidad de USDC cent (1e4 = $0.0001 USDC)
    ///         Para simplificar: 1 token = 1 micro-USDC (1e0 unidades de 6 decimales)
    ///         totalTokens = montoTotalUSDC (misma magnitud)
    uint256 public immutable totalTokens;

    uint256 public constant MIN_INVESTMENT = 1e6; // 1 USDC
    uint256 public constant MAX_INVESTMENT = 10_000e6; // 10,000 USDC

    // -------------------------------------------------------------------------
    // Eventos
    // -------------------------------------------------------------------------

    event InvestmentReceived(
        address indexed investor, uint256 usdcAmount, uint256 tokensMinted, uint256 timestamp
    );
    event ProjectActivated(address indexed beneficiario, uint256 montoTotal, uint256 plazoMeses);
    event MesesPagadosUpdated(uint256 mesesPagados, uint256 plazoMeses);
    event ProjectAddressesSet(address paymentSplitter, address ownershipTransfer);

    // -------------------------------------------------------------------------
    // Modificadores
    // -------------------------------------------------------------------------

    modifier onlyPaymentSplitter() {
        require(msg.sender == _metadata.paymentSplitter, "SolarProject: solo PaymentSplitter");
        _;
    }

    modifier onlyOwnershipTransfer() {
        require(
            msg.sender == _metadata.ownershipTransfer, "SolarProject: solo OwnershipTransfer"
        );
        _;
    }

    modifier proyectoActivo() {
        require(_metadata.activo, "SolarProject: proyecto inactivo");
        _;
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _beneficiario Wallet del dueño del hogar
    /// @param _cuotaMensualUSDC Cuota mensual calculada por Core ML, en USDC (6 decimales)
    /// @param _montoTotalUSDC Monto total a financiar = cuota * plazo (aprox)
    /// @param _plazoMeses 12, 24 o 36
    /// @param _rendimientoBps Rendimiento anual para inversores en basis points
    /// @param _ciudad Ciudad del proyecto (para el explorador)
    /// @param _estado Estado/entidad federativa
    /// @param _usdc Dirección del token USDC en la red
    constructor(
        address _beneficiario,
        uint256 _cuotaMensualUSDC,
        uint256 _montoTotalUSDC,
        uint256 _plazoMeses,
        uint256 _rendimientoBps,
        string memory _ciudad,
        string memory _estado,
        address _usdc
    ) FractionToken(msg.sender) {
        // msg.sender = Factory; el ownership se transfiere al beneficiario en setProjectAddresses()
        require(_beneficiario != address(0), "SolarProject: beneficiario zero");
        require(
            _plazoMeses == 12 || _plazoMeses == 24 || _plazoMeses == 36,
            "SolarProject: plazo invalido (12/24/36)"
        );
        require(_montoTotalUSDC > 0, "SolarProject: monto debe ser > 0");
        require(_cuotaMensualUSDC > 0, "SolarProject: cuota debe ser > 0");
        require(_usdc != address(0), "SolarProject: usdc zero");

        usdc = IERC20(_usdc);
        totalTokens = _montoTotalUSDC; // 1 token = 1 unidad de USDC (6 dec)

        _metadata = Metadata({
            beneficiario: _beneficiario,
            cuotaMensualUSDC: _cuotaMensualUSDC,
            montoTotalUSDC: _montoTotalUSDC,
            plazoMeses: _plazoMeses,
            rendimientoBps: _rendimientoBps,
            mesesPagados: 0,
            fechaInicio: block.timestamp,
            activo: true,
            ciudad: _ciudad,
            estado: _estado,
            paymentSplitter: address(0),
            ownershipTransfer: address(0)
        });

        emit ProjectActivated(_beneficiario, _montoTotalUSDC, _plazoMeses);
    }

    // -------------------------------------------------------------------------
    // Setup (llamado por Factory después del deploy)
    // -------------------------------------------------------------------------

    /// @notice Configura las direcciones de PaymentSplitter y OwnershipTransfer.
    ///         Solo puede llamarse una vez, por el owner (la Factory).
    function setProjectAddresses(address paymentSplitter, address ownershipTransfer)
        external
        onlyOwner
    {
        require(_metadata.paymentSplitter == address(0), "SolarProject: ya configurado");
        require(
            paymentSplitter != address(0) && ownershipTransfer != address(0),
            "SolarProject: zero address"
        );

        _metadata.paymentSplitter = paymentSplitter;
        _metadata.ownershipTransfer = ownershipTransfer;

        emit ProjectAddressesSet(paymentSplitter, ownershipTransfer);

        // Transferir ownership al beneficiario para que quede bajo su control
        _transferOwnership(_metadata.beneficiario);
    }

    // -------------------------------------------------------------------------
    // Flujo inversor
    // -------------------------------------------------------------------------

    /// @notice El inversor deposita USDC y recibe tokens fraccionados proporcionales.
    ///         Requiere approve() previo de USDC a esta dirección.
    /// @param usdcAmount Cantidad de USDC a invertir (en unidades de 6 decimales)
    function invest(uint256 usdcAmount) external nonReentrant proyectoActivo {
        require(usdcAmount >= MIN_INVESTMENT, "SolarProject: inversion minima 1 USDC");
        require(usdcAmount <= MAX_INVESTMENT, "SolarProject: inversion maxima 10,000 USDC");

        uint256 tokensDisponibles = totalTokens - totalSupply();
        require(tokensDisponibles > 0, "SolarProject: proyecto completamente financiado");

        // Si el inversor quiere más de lo disponible, se limita al resto
        uint256 usdcEfectivo = usdcAmount;
        if (usdcEfectivo > tokensDisponibles) {
            usdcEfectivo = tokensDisponibles;
        }

        require(
            usdc.transferFrom(msg.sender, _metadata.paymentSplitter, usdcEfectivo),
            "SolarProject: transferencia USDC fallida"
        );

        _mintTokens(msg.sender, usdcEfectivo);

        emit InvestmentReceived(msg.sender, usdcEfectivo, usdcEfectivo, block.timestamp);
    }

    // -------------------------------------------------------------------------
    // Llamadas desde PaymentSplitter
    // -------------------------------------------------------------------------

    /// @notice Incrementa el contador de meses pagados. Solo PaymentSplitter puede llamar.
    function incrementMesesPagados() external onlyPaymentSplitter {
        require(
            _metadata.mesesPagados < _metadata.plazoMeses, "SolarProject: plazo ya completado"
        );
        _metadata.mesesPagados += 1;
        emit MesesPagadosUpdated(_metadata.mesesPagados, _metadata.plazoMeses);
    }

    // -------------------------------------------------------------------------
    // Llamadas desde OwnershipTransfer
    // -------------------------------------------------------------------------

    /// @notice Quema todos los tokens de inversores y marca el proyecto como inactivo.
    ///         Solo OwnershipTransfer puede llamar esto.
    function finalizeProject() external onlyOwnershipTransfer {
        require(_metadata.activo, "SolarProject: ya finalizado");
        _burnAllTokens();
        _metadata.activo = false;
    }

    // -------------------------------------------------------------------------
    // Vistas
    // -------------------------------------------------------------------------

    /// @notice Devuelve los metadatos completos del proyecto (consumido por la app iOS)
    function getProjectMetadata() external view returns (Metadata memory) {
        return _metadata;
    }

    /// @notice Porcentaje de tokens financiados (0–10000 bps = 0–100%)
    function porcentajeFinanciadoBps() external view returns (uint256) {
        if (totalTokens == 0) return 0;
        return (totalSupply() * 10_000) / totalTokens;
    }

    /// @notice Porcentaje pro-rata de un inversor específico (0–10000 bps)
    function getInvestorShare(address investor) external view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) return 0;
        return (balanceOf(investor, TOKEN_ID) * 10_000) / supply;
    }

    /// @notice Porcentaje de propiedad del beneficiario sobre el panel (basado en meses pagados)
    function getPorcentajePropiedad() external view returns (uint256) {
        if (_metadata.plazoMeses == 0) return 0;
        return (_metadata.mesesPagados * 10_000) / _metadata.plazoMeses;
    }
}
