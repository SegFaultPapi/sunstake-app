# Sunstake Smart Contracts

Contratos Solidity para Sunstake en Base Network (L2 Ethereum).
Desarrollados con **Foundry** y **OpenZeppelin v5**.

## Arquitectura

```
SunstakeFactory (1 deploy)
    └── createProject() despliega por proyecto:
            ├── SolarProject (ERC-1155 + metadata)
            ├── PaymentSplitter (distribuye USDC)
            └── OwnershipTransfer (cierre del proyecto)

FractionToken (base abstracta)
    └── SolarProject hereda de FractionToken
```

## Contratos

| Contrato | Descripción |
|----------|-------------|
| `FractionToken.sol` | Base abstracta ERC-1155 con tracking de `investors[]` |
| `SolarProject.sol` | 1 deploy por proyecto. Metadata + tokens fraccionados. `invest()` para inversores |
| `PaymentSplitter.sol` | Recibe USDC del beneficiario, distribuye 93% a inversores + 7% fee a Sunstake |
| `OwnershipTransfer.sol` | Quema todos los tokens y emite evento de propiedad al completar el plazo |
| `SunstakeFactory.sol` | Desplegado 1 vez. `createProject()` despliega los 3 contratos en 1 tx |

## Flujo de dinero

```
Beneficiario.approve(paymentSplitter, cuota)
→ PaymentSplitter.payMonthly()
    → 7% → Sunstake Treasury
    → 93% distribuido pro-rata a cada inversor (según balance de tokens)
    → SolarProject.incrementMesesPagados()
    → [si último mes] OwnershipTransfer.completeProject()
        → Quema todos los tokens de inversores
        → Emite PropiedadTransferida (hash = título de propiedad)
```

## Red

| Red | Chain ID | USDC |
|-----|----------|------|
| Base Sepolia (demo) | 84532 | `0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f` (TestnetERC20, 6 dec.) |
| Base Mainnet | 8453 | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` (USDC oficial Circle, 6 dec.) |

> En Base Sepolia usamos un USDC de pruebas con faucet generoso en [staging.aave.com/faucet](https://staging.aave.com/faucet) (selecciona Base Sepolia).

## Setup

```bash
# Instalar Foundry
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Instalar dependencias
forge install

# Compilar
forge build

# Tests (28 tests, 0 failures)
forge test --summary
```

## Deploy en Base Sepolia

```bash
# 1. Configurar variables de entorno
cp .env.example .env
# Editar .env con PRIVATE_KEY, BASESCAN_API_KEY, SUNSTAKE_TREASURY

# 2. Deploy de la Factory (solo se hace una vez)
forge script script/Deploy.s.sol \
  --rpc-url base_sepolia \
  --private-key $PRIVATE_KEY \
  --broadcast --verify -vvvv

# 3. Añadir FACTORY_ADDRESS al .env con la dirección impresa en el paso anterior

# 4. Seed de datos de demo (3 proyectos + inversores + 2 ciclos de pago)
# Requiere USDC en Base Sepolia: https://faucet.circle.com
forge script script/SeedDemo.s.sol \
  --rpc-url base_sepolia \
  --private-key $PRIVATE_KEY \
  --broadcast -vvvv
```

## Integración con la app iOS

Después del deploy, el script imprime las addresses. Añadirlas como constantes en `BlockchainService.swift`:

```swift
static let factoryAddress = "0x..."  // SunstakeFactory
```

La app iOS llama `SunstakeFactory.createProject()` cuando el beneficiario publica su proyecto, y usa `SolarProject.invest()` cuando un inversor compra fracciones.

## Tests

```bash
forge test -vvv          # verbose con traces
forge test --summary     # resumen por suite
forge test --gas-report  # análisis de gas
```

| Suite | Tests |
|-------|-------|
| SolarProjectTest | 11 |
| PaymentSplitterTest | 9 |
| OwnershipTransferTest | 8 |
| **Total** | **28** |
