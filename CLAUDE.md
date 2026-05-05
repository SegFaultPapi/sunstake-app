# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Sunstake** is an iOS app (SwiftUI, iOS 16+) for tokenized solar panel financing on blockchain. Homeowners (beneficiaries) publish solar projects as smart contracts; investors purchase fractional ERC-1155 tokens and receive monthly yield distributions. Built for Swift Changemakers Hackathon 2026 — Human Centered AI.

> "Sunstake tokeniza paneles solares en Base: tú pones $1 USDC, una familia paga menos luz, adquiere el panel a cuotas, y cada peso queda en blockchain."

> **La IA sugiere. El beneficiario decide. El contrato inteligente ejecuta. El inversor verifica.**

Full specs: `docs/sunstake-prd.md` | `docs/sunstake-mvp.md` | `docs/sunstake-bmc.md`

---

## Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| UI | SwiftUI (iOS 16+) | SF Pro typography only, native components |
| Persistence | SwiftData (iOS 17) | History, favorites, profile |
| On-device ML | Core ML | Quota calculator, never leaves device |
| AI explanations | Foundation Models (iOS 18) | Natural language breakdown, on-device |
| Crypto primitives | CryptoKit + Secure Enclave | Signs transactions, key never leaves device |
| Auth | LocalAuthentication | Face ID / Touch ID + 6-digit PIN fallback |
| Blockchain | Base Network L2 | ERC-1155 tokens, USDC stablecoin |
| Embedded wallet | Privy SDK | No seed phrase ever shown to user |
| Solar data | NASA POWER API | Real solar radiation by coordinates |
| Chain read/write | Base RPC | Public + Alchemy backup |
| TX verification | Basescan API | User-visible transaction links |

---

## User Personas

### Ana — Beneficiary
- Homeowner in urban/semi-urban Mexico, CFE bill ~$1,200 MXN/month
- No savings for solar installation, iPhone SE iOS 16, zero crypto experience
- Needs: savings in pesos (not kWh), no technical jargon, visible breakdown as trust signal
- Pain points: "El panel cuesta $60k, jamás lo voy a pagar" · "¿Cómo sé que no me van a robar los pagos?"

### Carlos — Investor
- 25–40 professional, ~$15k MXN to invest, basic fintech experience
- Needs: transaction hash he can verify himself, CO₂ impact data, step-by-step purchase confirmation
- Pain points: "CETES dan 11% pero me siento mal" · "No confío en el rendimiento si no lo veo yo mismo"

---

## Business Model

**Revenue streams:**
- **Platform fee on yield**: Sunstake retains 5–8% of gross yield before distributing to investors
- **Origination fee**: 1–2% of financed amount when project is published
- **Installer commission**: $1,500–$3,000 MXN per completed installation (marketplace model)

**Money flow:**
```
Beneficiary pays monthly quota in USDC
    → PaymentSplitter.sol receives payment
        → 92–95% distributed to investors pro-rata
        → 5–8% sent to Sunstake wallet (fee)
    → Basescan records entire transaction
```

**Unit economics (reference project):** Panel 2kW = $45,000 MXN financed ≈ $2,250 USD · 36-month term · ~$70 USD/month · ~9% annual yield for investor · 7% Sunstake fee = ~$6,300 MXN per project over 36 months.

---

## Architecture

### HCAI Compliance — Every Feature Must Pass All 10

| # | Principle | Implementation |
|---|-----------|---------------|
| 1 | Explainability | Show all 4 variables in quota breakdown |
| 2 | User control | Override of AI-suggested payment terms always enabled, never blockable |
| 3 | Transparent data | NASA POWER API source visible in calculation UI |
| 4 | Verifiable trust | Every transaction has Basescan link; contract auditable directly |
| 5 | Low cognitive load | Separate linear flows per role; no mixed UI |
| 6 | Inclusivity | Zero crypto experience required; Privy embeds wallet, no seed phrase |
| 7 | Privacy | Core ML + Foundation Models run fully on-device |
| 8 | Responsible design | Biometric confirmation required before every financial transaction |
| 9 | Sustainability | Base L2 (low gas), on-device models (no cloud compute) |
| 10 | Interpretability | Descriptive loader states, visible calculation steps, hash per tx |

### Smart Contracts (Base Network)

| Contract | Role | Key Functions |
|----------|------|--------------|
| `SolarProject.sol` | ERC-1155 collection per project; stores metadata (quota, term, beneficiary, expected yield) | `publishProject()`, `getProjectMetadata()` |
| `FractionToken.sol` | Extends ERC-1155; mints/manages fractional tokens | `mint()`, `balanceOf()`, `totalSupply()` |
| `PaymentSplitter.sol` | Receives monthly payments; distributes yield pro-rata; retains platform fee | `receivePayment()`, `distributeYield()`, `getPlatformFee()` |
| `OwnershipTransfer.sol` | Burns investor tokens when beneficiary completes term | `completeProject()`, `burnInvestorTokens()`, `transferOwnership()` |

- **Testnet (demo):** Base Sepolia (chain ID: 84532) — `https://sepolia.base.org`
- **Production:** Base Mainnet (chain ID: 8453) — `https://mainnet.base.org`
- **USDC on Base Mainnet:** `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` (USDC oficial Circle, 6 decimales)
- **USDC on Base Sepolia (demo):** `0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f` (TestnetERC20, 6 decimales). Faucet con mint generoso: [staging.aave.com/faucet](https://staging.aave.com/faucet) (selecciona Base Sepolia).

### Core ML Model — Quota Calculator

**Inputs:**
```
consumo_kwh: Float          // monthly kWh, entered manually
horas_sol: Float            // daily sun hours from NASA POWER
precio_panel_instalacion: Float  // internal catalog, in MXN
plazo_meses: Int            // 12, 24, or 36
inflacion_estimada: Float   // constant: 0.048
```

**Outputs:**
```
cuota_mensual: Float        // in MXN
cobertura_porcentaje: Float // % of CFE consumption covered
rendimiento_inversor: Float // projected annual %
confianza: Enum { alta, media, baja }
```

V1 strategy: manually calibrated linear model if real historical data (CRE/ANES) is unavailable.

### External APIs

| API | Endpoint | Rate Limit | Fallback |
|-----|----------|-----------|---------|
| NASA POWER | `https://power.larc.nasa.gov/api/temporal/daily/point` | No documented limit | Hardcoded regional averages by state |
| Base RPC | `https://sepolia.base.org` / `https://mainnet.base.org` | 10 req/s (public) | Alchemy backup RPC |
| Basescan | `https://api.basescan.org/api` | 5 req/s (free) | Local cache |

### Data Flow

- **Offline-first**: Core ML runs locally; only final results go to blockchain.
- **Biometric gate**: Face ID / Touch ID before every transaction; no auto-payments ever.
- **Async state**: All blockchain ops show descriptive loader states ("Creando contrato...", "Emitiendo tokens...", "¡Proyecto publicado!").
- **Local cache**: SwiftData for history; offline project explorer fallback.
- **Privacy**: Private key never leaves Secure Enclave. Consumption data never sent to Sunstake servers.

---

## User Flows

### Flow A — Beneficiary: First Quota
```
Splash → Onboarding (3 screens) → Role selection (Beneficiary)
    → Form (consumption + location + term)
    → AI calculation loader (<5s)
    → Result with 4-variable breakdown + confidence bar
        → [Override] Adjust term → Instant recalculation (<500ms, on-device)
        → [Confirm] Full summary screen
            → [Face ID] → Loader ("Creando contrato...")
                → Success: Dashboard with hash + Basescan link
                → Error: Specific message + Retry
```

### Flow B — Investor: First Investment
```
Onboarding → Role selection (Investor)
    → Project explorer (list with filters)
    → Project detail (metrics + contract address)
        → [Invest] Step 1: Select amount (min $1 USDC)
            → Step 2: Summary (tokens + yield + gas fee in USD/MXN)
                → [Face ID] Step 3: Confirmation
                    → Loader ("Procesando en Base Network...")
                        → Success: Hash + Basescan link + expected yield
                        → Error: Message + Retry
```

### Flow C — Beneficiary: Monthly Payment
```
Push notification → App opens on Dashboard
    → "Pagar cuota de [month]" button with amount + date
        → Payment summary (USDC amount + estimated gas fee)
            → [Face ID] Confirmation
                → Loader → Success: Hash + updated ownership %
```

---

## Business Rules & Constraints

| Constraint | Rule |
|-----------|------|
| Minimum investment | $1 USD in USDC |
| Maximum per investor per project | $10,000 USD |
| Available terms | 12, 24, 36 months only |
| Currency | USDC on Base only in MVP |
| Gas fee warning | If estimated >$0.50 USD, warn user explicitly |
| Projects per beneficiary | 1 active project maximum in MVP |
| AI override | Always available, never blockable |
| Seed phrase | Never shown anywhere in the app |
| Private key | Never transmitted to Sunstake servers |

---

## What Is NOT in MVP

- Chat between investor and beneficiary
- Secondary token market (resale of fractions)
- CFE API integration
- Multi-chain support (Base Network only)
- Governance token or voting mechanism
- Project rating/review system
- Installer admin panel
- Electricity tariff comparator

---

## UI Language Glossary (Technical → User-Facing)

| Technical Term | App UI Text |
|---------------|------------|
| ERC-1155 token | "Tu participación en el proyecto" |
| Smart Contract | "Contrato registrado en blockchain" |
| USDC | "Dólares digitales estables" |
| Base Network | "Red de pagos verificables" |
| Transaction hash | "Código de verificación" |
| Wallet | "Tu cuenta de pagos" |
| Gas fee | "Costo de procesamiento" |
| Base Sepolia | "Modo de prueba" |

---

## Design System

- **Typography:** SF Pro (system iOS) only — no external fonts
- **Dark mode:** Native system preference support required
- **Accessibility:** Dynamic Type on all text (minimum `.body`), VoiceOver labels on all interactive elements, WCAG AA contrast (4.5:1 minimum), reduce motion support on animations
- **Confirmation pattern:** Every financial flow has a review screen before the final CTA

---

## Build & Run (once Xcode project is initialized)

```bash
# Open project
open SunstakeApp.xcodeproj

# Build via CLI
xcodebuild build -scheme SunstakeApp -destination 'platform=iOS Simulator,name=iPhone 16'

# Run tests
xcodebuild test -scheme SunstakeApp -destination 'platform=iOS Simulator,name=iPhone 16'
```

iOS 16 minimum target. All Foundation Models usage must be wrapped in `#available(iOS 18, *)` with static text fallback.

---

## Key Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Foundation Models (iOS 18) unavailable | Feature flag + static explanation text fallback |
| Privy SDK issues | WalletConnect as alternative |
| NASA POWER API down | Hardcoded regional averages by state |
| Base Sepolia instability | Alchemy RPC backup |
| Core ML model quality | Manually calibrated linear formula as V1 |
| Smart contract bug | Contracts verified on Basescan Sepolia; testnet only for demo |

---

## Success Criteria

| KPI | Target |
|-----|-------|
| Beneficiary flow (onboarding → quota) | < 3 minutes |
| Investor flow (onboarding → investment) | < 2 minutes |
| Users understanding AI breakdown without help | > 80% |
| Users finding transaction hash | > 90% |
| Transaction success rate on first attempt | > 95% |
| Core ML calculation time | < 5 seconds |
| TX confirmation time on Base Sepolia | < 5 seconds |
| VoiceOver label coverage | 100% of interactive elements |

## Implementation Phases (Hackathon)

| Phase | Focus | Est. Points |
|-------|-------|------------|
| 0 | Xcode setup, Privy SDK, contracts on Sepolia, NASA API | — |
| 1 | Beneficiary core: form → Core ML → override → publish contract → dashboard | 20 SP |
| 2 | Investor core: project explorer → 3-step purchase → yield history | 14 SP |
| 3 | HCAI polish: Foundation Models text, confidence bar, contract view, VoiceOver, loaders | 11 SP |
| 4 | Notifications, onboarding screens, CSV export, dark mode test | 11 SP |
| 5 | Demo prep: seed Sepolia with 3–5 projects, simulate 2 payment cycles, pitch rehearsal | — |

## When inserting new code

It is really important that, for feature you develop/update, you use the defined color in Sunstake/DesignSystem/ColorPalette.swift, do NOT create new colors, not even in the specified file, not even hard coded. Just use the one defined there.
