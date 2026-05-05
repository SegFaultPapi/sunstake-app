# MVP Scope: Sunstake

> Financiamiento colectivo de paneles solares con fracciones tokenizadas en blockchain y IA centrada en el humano.

---

## Problema Core

Familias mexicanas no pueden acceder a energía solar por el costo inicial elevado, mientras inversores con pequeños ahorros no tienen vehículos de impacto real y rendimiento garantizado. La falta de transparencia y trazabilidad en la distribución de pagos genera desconfianza en ambos lados.

---

## Flujo MVP

### Flujo Beneficiario
1. Beneficiario ingresa consumo eléctrico actual y ubicación (CP o mapa)
2. La IA calcula cuota mensual personalizada con desglose visible de cada variable
3. Beneficiario acepta, ajusta o rechaza la propuesta antes de publicar su proyecto
4. El proyecto se publica como un Smart Contract en Base Network (ERC-1155 fraccionado)
5. Beneficiario paga cuota mensual on-chain y ve progreso de propiedad del panel en tiempo real

### Flujo Inversor
1. Inversor explora proyectos con datos de impacto ambiental medible (CO₂ evitado, kWh generados)
2. Adquiere fracciones del proyecto (tokens ERC-1155) desde $1 USD en USDC sobre Base
3. Recibe rendimiento mensual automático distribuido por el Smart Contract
4. Consulta historial de pagos con hash de transacción verificable en Base Explorer

---

## Features MVP

### Beneficiario
- **Calculadora IA de cuota ideal** con desglose visible (consumo, radiación solar, plazo, margen)
- **Override explícito**: el usuario puede ajustar plazo o monto antes de confirmar
- **Dashboard de propiedad progresiva**: % de tokens adquiridos, meses restantes, historial on-chain
- **Notificaciones de pago** confirmado en blockchain

### Inversor
- **Explorador de proyectos** con filtros: región, rendimiento esperado, plazo, impacto CO₂
- **Compra de fracciones** (tokens ERC-1155) con confirmación paso a paso y resumen de gas fee
- **Historial de rendimientos** con hash de transacción verificable públicamente
- **Notificación de rendimiento** recibido cada mes

### Compartido
- Autenticación segura con Face ID / Touch ID + wallet embebida (Privy o WalletConnect)
- Visualización del contrato inteligente activo (dirección, estado, plazo)

---

## NO va en MVP
- Chat entre inversor y beneficiario
- Mercado secundario de tokens (reventa de fracciones)
- Comparador de tarifas eléctricas
- Integración directa con CFE API
- Sistema de reseñas o calificaciones de proyectos
- Panel de administración para instaladores
- Soporte multi-chain (solo Base Network en MVP)
- Governance token o mecanismo de votación

---

## Arquitectura Blockchain

### Red
- **Base Network** (L2 de Ethereum, bajo costo de gas, rápido, ecosistema Coinbase)

### Contratos Inteligentes
| Contrato | Función |
|----------|---------|
| `SolarProject.sol` | Representa cada proyecto como colección ERC-1155. Almacena metadatos: cuota, plazo, beneficiario, rendimiento esperado |
| `FractionToken.sol` | Emite y gestiona tokens fraccionados de cada proyecto (ERC-1155) |
| `PaymentSplitter.sol` | Recibe el pago mensual del beneficiario y distribuye rendimientos a inversores automáticamente pro-rata |
| `OwnershipTransfer.sol` | Al completar el plazo, transfiere la propiedad simbólica del panel 100% al beneficiario (quema tokens de inversores) |

### Moneda
- **USDC en Base** para pagos y rendimientos (estable, sin volatilidad para el beneficiario)

### Trazabilidad
- Cada pago queda registrado con hash de transacción verificable en [Basescan](https://basescan.org)
- Los inversores pueden auditar el contrato directamente sin confiar en Sunstake

---

## Rol de la IA (HCAI explícito)

La IA calcula la cuota óptima usando:
- Consumo promedio del beneficiario (kWh/mes, ingresado manualmente)
- Radiación solar de su zona (NASA POWER API — gratuita y pública)
- Precio referencia del panel + instalación (catálogo interno)
- Plazo seleccionado por el usuario

### Lo que la IA muestra al usuario
```
"Tu cuota sería $850 MXN/mes porque:
  • Consumes 320 kWh/mes
  • Tu zona recibe 5.2 horas de sol al día (Guadalajara, JAL)
  • El panel de 2kW cubre el 87% de tu consumo
  • A 36 meses, pagas menos que tu factura actual"
```

- **Barra de confianza del cálculo**: Alta / Media / Baja según calidad de datos disponibles
- **Botón de ajuste manual**: el usuario puede modificar el plazo (12, 24, 36 meses) y ver cómo cambia la cuota
- **Explicación en lenguaje natural** generada con Foundation Models (on-device)

> La IA sugiere. El beneficiario decide. El contrato inteligente ejecuta. El inversor verifica.

---

## Consideraciones HCAI para el Hackathon

| Principio | Implementación en MVP |
|-----------|----------------------|
| **Control humano** | Beneficiario ajusta plazo/monto antes de confirmar; inversor revisa y confirma cada transacción |
| **Interpretabilidad** | Desglose visible del cálculo IA variable por variable + explicación en lenguaje natural |
| **Confianza** | Hash de transacción visible; contrato verificable en Basescan; sin caja negra |
| **Equidad** | Sin jerga financiera ni blockchain; flujo simplificado para usuarios sin experiencia en cripto |
| **Privacidad** | Cálculo de cuota on-device con Core ML; wallet embebida sin exponer claves al servidor |
| **Carga cognitiva** | Dos flujos separados y lineales; la complejidad de blockchain es invisible para el usuario |
| **Sustentabilidad** | Modelo ligero on-device, Base es L2 de bajo consumo energético vs. Ethereum L1 |
| **Diseño responsable** | Confirmación obligatoria antes de cualquier transacción; no hay transacciones automáticas sin aprobación |

---

## Stack Técnico

### iOS App (Swift — permitido por hackathon)
| Tecnología | Uso |
|------------|-----|
| **SwiftUI** | Interfaces de ambos flujos (beneficiario e inversor) |
| **Core ML** | Modelo de cálculo de cuota on-device |
| **Foundation Models** | Explicación en lenguaje natural del cálculo IA (on-device, iOS 18+) |
| **SwiftData** | Persistencia local: historial, favoritos, perfil |
| **CryptoKit** | Firma de transacciones y seguridad de wallet local |

### APIs Públicas y Gratuitas
| API | Uso |
|-----|-----|
| **NASA POWER API** | Datos de radiación solar por coordenadas GPS |
| **Base Network RPC** | Lectura de contratos y envío de transacciones |
| **Basescan API** | Verificación pública de transacciones |

### Blockchain
| Componente | Tecnología |
|------------|------------|
| Red | **Base Network** (L2 Ethereum, Coinbase) |
| Tokens | **ERC-1155** (fracciones de proyecto) |
| Moneda | **USDC on Base** |
| Wallet | **Privy SDK** (wallet embebida, sin seed phrase visible) |
| Contratos | **Solidity** — desplegados en Base Sepolia (testnet para demo) |

---

## Criterio de Éxito

> El MVP funciona si:
> - Un beneficiario genera, entiende y acepta su cuota en **menos de 3 minutos**
> - Un inversor compra una fracción de un proyecto en **menos de 2 minutos**
> - Cada pago mensual queda registrado con un **hash verificable en Basescan**
> - El beneficiario puede ver en todo momento **cuánto del panel ya es suyo**

---

## Test Final

- [x] **Test de 30 segundos**: *"Sunstake tokeniza paneles solares en Base: tú pones $1 USDC, una familia paga menos luz, adquiere el panel a cuotas, y cada peso queda en blockchain."*
- [x] **Test de enfoque**: 4 features críticas por perfil de usuario
- [x] **Test de problema**: Resuelve acceso a solar sin capital inicial + trazabilidad de pagos con blockchain

---

## Red Flags HCAI resueltos

| Riesgo | Mitigación |
|--------|------------|
| Usuario sin experiencia en crypto | Wallet embebida (Privy), sin seed phrases, sin terminología blockchain en el UI |
| Desconfianza en el cálculo de la IA | Desglose completo visible, modelo explicable, ajuste manual habilitado |
| Pérdida de fondos por bug en contrato | Contratos auditables públicamente en Basescan; testnet en demo |
| Exclusión de usuarios sin smartphone moderno | Target mínimo iOS 16, compatible con iPhone SE |
| Sesgo en el cálculo de cuota por zona geográfica | Datos NASA POWER cubre todo México; se muestra el dato de radiación usado |

---

*MVP definido bajo criterios del Swift Changemakers Hackathon 2026 — Human Centered AI*
*Stack: SwiftUI · Core ML · Foundation Models · Base Network · ERC-1155 · USDC · Privy*
