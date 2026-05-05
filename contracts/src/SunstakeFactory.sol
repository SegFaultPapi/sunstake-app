// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SolarProject.sol";
import "./PaymentSplitter.sol";
import "./OwnershipTransfer.sol";

/// @title SunstakeFactory
/// @notice Contrato desplegado UNA SOLA VEZ en Base Sepolia.
///         La app iOS apunta siempre a esta dirección.
///         Cuando un beneficiario publica su proyecto, la app llama createProject()
///         y la Factory despliega los 3 contratos enlazados en una sola transacción.
///
///         Flujo de despliegue por proyecto:
///         1. Deploy SolarProject (metadata + ERC-1155)
///         2. Deploy OwnershipTransfer (referencia a SolarProject)
///         3. Deploy PaymentSplitter (referencia a SolarProject + OwnershipTransfer)
///         4. OwnershipTransfer.setPaymentSplitter(paymentSplitter)
///         5. SolarProject.setProjectAddresses(paymentSplitter, ownershipTransfer)
contract SunstakeFactory is Ownable {
    // -------------------------------------------------------------------------
    // Estado
    // -------------------------------------------------------------------------

    address public immutable usdc;
    address public sunstakeTreasury;
    uint256 public platformFeeBps;

    address[] private _projects;
    mapping(address => address) public projectToSplitter;
    mapping(address => address) public projectToOwnershipTransfer;
    mapping(address => address) public projectToBeneficiario;

    // -------------------------------------------------------------------------
    // Eventos
    // -------------------------------------------------------------------------

    event ProjectCreated(
        address indexed solarProject,
        address indexed paymentSplitter,
        address indexed ownershipTransfer,
        address beneficiario,
        string ciudad,
        string estado,
        uint256 montoTotalUSDC,
        uint256 plazoMeses,
        uint256 timestamp
    );

    event TreasuryUpdated(address oldTreasury, address newTreasury);
    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _usdc Dirección de USDC en la red (Base Sepolia o Mainnet)
    /// @param _sunstakeTreasury Wallet de Sunstake para recibir fees
    /// @param _platformFeeBps Fee de plataforma en basis points (500-800)
    constructor(address _usdc, address _sunstakeTreasury, uint256 _platformFeeBps)
        Ownable(msg.sender)
    {
        require(_usdc != address(0), "Factory: usdc zero");
        require(_sunstakeTreasury != address(0), "Factory: treasury zero");
        require(
            _platformFeeBps >= 500 && _platformFeeBps <= 800,
            "Factory: fee fuera de rango 5-8%"
        );

        usdc = _usdc;
        sunstakeTreasury = _sunstakeTreasury;
        platformFeeBps = _platformFeeBps;
    }

    // -------------------------------------------------------------------------
    // Creación de proyectos
    // -------------------------------------------------------------------------

    /// @notice Despliega un nuevo proyecto solar tokenizado con todos sus contratos asociados.
    ///         Llamado por la app iOS cuando el beneficiario confirma su cuota con Face ID.
    ///
    /// @param cuotaMensualUSDC Cuota calculada por Core ML, en USDC (6 decimales). Ej: 48_570_000 = $48.57 USDC
    /// @param montoTotalUSDC   Monto total a financiar = cuota * plazo aprox. Ej: 2_250_000_000 = $2,250 USDC
    /// @param plazoMeses       Plazo en meses: 12, 24 o 36
    /// @param rendimientoBps   Rendimiento anual para inversores en bps. Ej: 920 = 9.2%
    /// @param ciudad           Ciudad del proyecto (para el explorador de la app)
    /// @param estado           Estado/entidad federativa
    ///
    /// @return solarProject      Dirección del SolarProject (contractAddress en la app iOS)
    /// @return paymentSplitter   Dirección del PaymentSplitter
    /// @return ownershipTransfer Dirección del OwnershipTransfer
    function createProject(
        uint256 cuotaMensualUSDC,
        uint256 montoTotalUSDC,
        uint256 plazoMeses,
        uint256 rendimientoBps,
        string calldata ciudad,
        string calldata estado
    )
        external
        returns (address solarProject, address paymentSplitter, address ownershipTransfer)
    {
        address beneficiario = msg.sender;

        // --- 1. Deploy SolarProject ---
        SolarProject sp = new SolarProject(
            beneficiario,
            cuotaMensualUSDC,
            montoTotalUSDC,
            plazoMeses,
            rendimientoBps,
            ciudad,
            estado,
            usdc
        );
        solarProject = address(sp);

        // --- 2. Deploy OwnershipTransfer ---
        OwnershipTransfer ot = new OwnershipTransfer(solarProject);
        ownershipTransfer = address(ot);

        // --- 3. Deploy PaymentSplitter ---
        PaymentSplitter ps = new PaymentSplitter(
            solarProject,
            ownershipTransfer,
            usdc,
            sunstakeTreasury,
            platformFeeBps
        );
        paymentSplitter = address(ps);

        // --- 4. Enlazar OwnershipTransfer con PaymentSplitter ---
        ot.setPaymentSplitter(paymentSplitter);

        // --- 5. Enlazar SolarProject con PaymentSplitter y OwnershipTransfer ---
        sp.setProjectAddresses(paymentSplitter, ownershipTransfer);

        // --- 6. Registrar en el registry de la Factory ---
        _projects.push(solarProject);
        projectToSplitter[solarProject] = paymentSplitter;
        projectToOwnershipTransfer[solarProject] = ownershipTransfer;
        projectToBeneficiario[solarProject] = beneficiario;

        emit ProjectCreated(
            solarProject,
            paymentSplitter,
            ownershipTransfer,
            beneficiario,
            ciudad,
            estado,
            montoTotalUSDC,
            plazoMeses,
            block.timestamp
        );
    }

    // -------------------------------------------------------------------------
    // Vistas
    // -------------------------------------------------------------------------

    /// @notice Devuelve todas las direcciones de SolarProject desplegados.
    ///         Usado por la app iOS para el explorador de proyectos.
    function getProjects() external view returns (address[] memory) {
        return _projects;
    }

    /// @notice Número total de proyectos creados
    function projectCount() external view returns (uint256) {
        return _projects.length;
    }

    /// @notice Devuelve los 3 contratos de un proyecto dado su SolarProject address
    function getProjectContracts(address solarProject)
        external
        view
        returns (address splitter, address ownershipTx, address beneficiario)
    {
        return (
            projectToSplitter[solarProject],
            projectToOwnershipTransfer[solarProject],
            projectToBeneficiario[solarProject]
        );
    }

    // -------------------------------------------------------------------------
    // Admin (solo owner)
    // -------------------------------------------------------------------------

    /// @notice Actualiza la wallet de Sunstake. Solo aplica a proyectos futuros.
    function updateTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Factory: treasury zero");
        emit TreasuryUpdated(sunstakeTreasury, newTreasury);
        sunstakeTreasury = newTreasury;
    }

    /// @notice Actualiza el fee de plataforma. Solo aplica a proyectos futuros.
    function updatePlatformFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps >= 500 && newFeeBps <= 800, "Factory: fee fuera de rango 5-8%");
        emit PlatformFeeUpdated(platformFeeBps, newFeeBps);
        platformFeeBps = newFeeBps;
    }
}
