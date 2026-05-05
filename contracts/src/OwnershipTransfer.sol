// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./SolarProject.sol";

/// @title OwnershipTransfer
/// @notice Gestiona el cierre del proyecto solar al completar el plazo:
///         quema los tokens de todos los inversores y emite un evento de
///         transferencia simbólica de propiedad al beneficiario.
///
///         El panel físico queda fuera de la cadena; este contrato registra
///         en blockchain el momento exacto en que el beneficiario adquiere
///         el 100% de su panel solar. El hash de esa transacción es su
///         "título de propiedad" verificable.
contract OwnershipTransfer {
    // -------------------------------------------------------------------------
    // Estado
    // -------------------------------------------------------------------------

    SolarProject public immutable project;

    /// @notice Dirección del PaymentSplitter que puede activar el cierre.
    ///         Se configura post-deploy via setPaymentSplitter() llamado por la Factory.
    address public paymentSplitter;

    bool public completed;
    uint256 public completedAt;

    // -------------------------------------------------------------------------
    // Eventos
    // -------------------------------------------------------------------------

    /// @notice Emitido cuando el beneficiario completa todos sus pagos.
    ///         El txHash de esta transacción es el "código de verificación"
    ///         que la app iOS muestra al beneficiario como prueba de propiedad.
    event ProyectoCompletado(
        address indexed project,
        address indexed beneficiario,
        uint256 montoTotalUSDC,
        uint256 plazoMeses,
        uint256 timestamp
    );

    /// @notice Emitido por cada token quemado de inversor
    event TokensQuemados(address indexed investor, uint256 cantidad, uint256 timestamp);

    /// @notice Transferencia simbólica de propiedad del panel al beneficiario
    event PropiedadTransferida(
        address indexed beneficiario, address indexed proyecto, uint256 timestamp
    );

    // -------------------------------------------------------------------------
    // Modificadores
    // -------------------------------------------------------------------------

    modifier soloPaymentSplitter() {
        require(msg.sender == paymentSplitter, "OwnershipTransfer: solo PaymentSplitter");
        _;
    }

    modifier noCompletado() {
        require(!completed, "OwnershipTransfer: ya completado");
        _;
    }

        /// @notice Address del owner temporal (la Factory) para configurar paymentSplitter
    address private immutable _factory;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _project Dirección del SolarProject asociado
    constructor(address _project) {
        require(_project != address(0), "OwnershipTransfer: project zero");
        project = SolarProject(_project);
        _factory = msg.sender;
    }

    // -------------------------------------------------------------------------
    // Setup (llamado por Factory después de desplegar PaymentSplitter)
    // -------------------------------------------------------------------------

    /// @notice Configura el PaymentSplitter autorizado. Solo puede llamarse una vez por la Factory.
    function setPaymentSplitter(address _paymentSplitter) external {
        require(msg.sender == _factory, "OwnershipTransfer: solo la factory");
        require(paymentSplitter == address(0), "OwnershipTransfer: ya configurado");
        require(_paymentSplitter != address(0), "OwnershipTransfer: splitter zero");
        paymentSplitter = _paymentSplitter;
    }

    // -------------------------------------------------------------------------
    // Función principal
    // -------------------------------------------------------------------------

    /// @notice Cierra el proyecto: quema todos los tokens de inversores y
    ///         transfiere la propiedad simbólica del panel al beneficiario.
    ///         Solo puede ser llamado por el PaymentSplitter en el último pago.
    function completeProject() external soloPaymentSplitter noCompletado {
        require(paymentSplitter != address(0), "OwnershipTransfer: splitter no configurado");
        SolarProject.Metadata memory meta = project.getProjectMetadata();
        require(
            meta.mesesPagados == meta.plazoMeses,
            "OwnershipTransfer: plazo no completado"
        );

        // 1. Quemar tokens de todos los inversores (registro individual)
        _burnAllInvestorTokens();

        // 2. Marcar el proyecto como finalizado en SolarProject
        project.finalizeProject();

        // 3. Registrar el cierre
        completed = true;
        completedAt = block.timestamp;

        // 4. Emitir eventos de cierre y transferencia simbólica
        emit ProyectoCompletado(
            address(project),
            meta.beneficiario,
            meta.montoTotalUSDC,
            meta.plazoMeses,
            block.timestamp
        );

        emit PropiedadTransferida(meta.beneficiario, address(project), block.timestamp);
    }

    // -------------------------------------------------------------------------
    // Internos
    // -------------------------------------------------------------------------

    /// @notice Itera todos los inversores del proyecto y emite evento por cada quema.
    ///         La quema real la ejecuta project.finalizeProject() (que llama _burnAllTokens).
    ///         Aquí solo emitimos los eventos individuales para trazabilidad.
    function _burnAllInvestorTokens() internal {
        address[] memory investors = project.getInvestors();
        for (uint256 i = 0; i < investors.length; i++) {
            uint256 balance = project.balanceOf(investors[i], project.TOKEN_ID());
            if (balance > 0) {
                emit TokensQuemados(investors[i], balance, block.timestamp);
            }
        }
    }

    // -------------------------------------------------------------------------
    // Vistas
    // -------------------------------------------------------------------------

    /// @notice Indica si el proyecto está completado
    function isCompleted() external view returns (bool) {
        return completed;
    }

    /// @notice Timestamp del cierre del proyecto (0 si aún no completado)
    function getCompletedAt() external view returns (uint256) {
        return completedAt;
    }
}
