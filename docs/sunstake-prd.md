# PRD — Sunstake MVP
**Product Requirements Document v1.0**
**Fecha:** Mayo 2026 | **Clasificación:** Interno · Development-Ready
**Hackathon:** Swift Changemakers 2026 — Human Centered AI

---

## Tabla de Contenidos

1. [Project Overview](#1-project-overview)
2. [User Personas & Insights](#2-user-personas--insights)
3. [Business Model](#3-business-model)
4. [User Stories & Acceptance Criteria](#4-user-stories--acceptance-criteria)
5. [UI/UX Requirements](#5-uiux-requirements)
6. [Technical Requirements](#6-technical-requirements)
7. [HCAI Compliance Checklist](#7-hcai-compliance-checklist)
8. [Success Metrics](#8-success-metrics)
9. [Implementation Roadmap](#9-implementation-roadmap)
10. [Apéndice & Glosario](#10-apéndice--glosario)

---

## 1. Project Overview

### 1.1 Problema

Tres fricciones simultáneas bloquean el acceso a energía solar en México:

| Fricción | Impacto |
|----------|---------|
| **Costo inicial elevado** ($30,000–$80,000 MXN por instalación) | El 68% de los hogares con facturas CFE >$800/mes no puede pagarlo de contado |
| **Inversión de impacto inaccesible** | Ahorradores con <$5,000 MXN no tienen instrumentos de inversión con rendimiento y propósito real |
| **Desconfianza en intermediarios** | Sin trazabilidad, los pagos en esquemas colectivos generan fraude percibido o real |

### 1.2 Solución

**Sunstake** es una plataforma iOS de financiamiento colectivo de paneles solares con fracciones tokenizadas en Base Network (L2 Ethereum). La IA calcula la cuota óptima del beneficiario, el Smart Contract distribuye automáticamente los rendimientos a inversores, y cada peso queda registrado con hash verificable en blockchain.

> "Sunstake tokeniza paneles solares en Base: tú pones $1 USDC, una familia paga menos luz, adquiere el panel a cuotas, y cada peso queda en blockchain."

### 1.3 Objetivos del MVP

| # | Objetivo | Métrica de Éxito |
|---|----------|-----------------|
| O1 | Beneficiario genera y entiende su cuota en <3 min | Tiempo medido en sesiones de prueba |
| O2 | Inversor compra fracción de proyecto en <2 min | Tiempo medido en sesiones de prueba |
| O3 | Cada pago mensual tiene hash verificable | 100% de pagos on-chain con Basescan link |
| O4 | Beneficiario ve % de propiedad del panel en tiempo real | Dashboard actualizado post-pago |
| O5 | Score HCAI ≥ 80/100 en rúbrica del hackathon | Evaluación de jueces |

### 1.4 Usuario Target

**Primario — Beneficiario (Ana):** Dueña de hogar en zona urbana/semiurbana de México, factura CFE >$800/mes, sin ahorros para instalación solar, smartphone básico (iPhone SE o superior, iOS 16+), nula experiencia en crypto.

**Secundario — Inversor (Carlos):** Joven profesional 25–40 años, ahorros disponibles $500–$50,000 MXN, busca alternativas a CETES con impacto real, puede tener experiencia básica en fintech pero no en blockchain.

---

## 2. User Personas & Insights

### 2.1 Persona A — Ana (Beneficiaria)

```
Nombre:       Ana Ramírez
Edad:         38 años
Ciudad:       Guadalajara, JAL
Ocupación:    Empleada administrativa
Factura CFE:  ~$1,200 MXN/mes
Smartphone:   iPhone SE (3ra gen), iOS 16
Crypto:       Nunca ha usado una wallet
Pain points:
  • "Me dijeron que el panel cuesta $60,000, jamás lo voy a pagar"
  • "No entiendo cómo funciona el financiamiento solar"
  • "¿Cómo sé que no me van a robar los pagos?"
Goals:
  • Reducir factura CFE >50%
  • Pagar en cómodas cuotas mensuales
  • Entender exactamente a qué se está comprometiendo
```

**Insights clave de Ana:**
- Necesita ver el ahorro en pesos, no en kWh — el beneficio debe ser tangible.
- Desconfía si hay terminología técnica (blockchain, token, wallet).
- El desglose del cálculo de la IA es su señal de confianza más importante.
- Prefiere notificaciones de confirmación sobre silencio post-pago.

### 2.2 Persona B — Carlos (Inversor)

```
Nombre:       Carlos Mendoza
Edad:         29 años
Ciudad:       Ciudad de México
Ocupación:    Desarrollador de software
Ahorros:      ~$15,000 MXN disponibles para invertir
Crypto:       Ha usado Binance, entiende básicos de wallet
Pain points:
  • "CETES dan 11%, pero me siento mal poniendo dinero ahí nomás"
  • "Las apps de inversión de impacto no muestran resultados reales"
  • "No confío en que el rendimiento llega si no lo veo yo mismo"
Goals:
  • Rendimiento mensual >8% anual
  • Trazabilidad total de sus pagos recibidos
  • Diversificar en proyectos por región y plazo
  • Sentir que ayuda a alguien concreto
```

**Insights clave de Carlos:**
- Quiere ver el hash de transacción — lo verificará él mismo en Basescan.
- El impacto ambiental (CO₂ evitado) es un diferenciador emocional real.
- Valora la transparencia del contrato más que el rendimiento en sí.
- La compra en pasos con confirmación le genera más confianza que un single-click.

---

## 3. Business Model

### 3.1 Fuentes de Ingreso

| Stream | Mecanismo | % / Monto |
|--------|-----------|-----------|
| **Fee de plataforma sobre rendimientos** | Sunstake retiene un % del rendimiento distribuido mensualmente antes de enviarlo al inversor | 5–8% del rendimiento bruto |
| **Fee de originación del proyecto** | Cobro único al publicar un proyecto (cubierto por el beneficiario o el instalador socio) | 1–2% del monto total financiado |
| **Tarifa sobre instalación** | Sunstake actúa como marketplace de instaladores socios certificados; cobra comisión por lead convertido | $1,500–$3,000 MXN por instalación completada |
| **Premium Inversor (futuro)** | Acceso anticipado a proyectos, analytics avanzados | $99 MXN/mes |

### 3.2 Flujo de Dinero (MVP)

```
Beneficiario paga cuota mensual en USDC
    → PaymentSplitter.sol recibe el pago
        → 92-95% distribuido a inversores pro-rata
        → 5-8% enviado a wallet de Sunstake (fee)
    → Basescan registra toda la transacción
```

### 3.3 Unit Economics (Proyecto Referencia)

- Panel 2kW: $45,000 MXN financiado ≈ $2,250 USD
- Plazo: 36 meses | Cuota beneficiario: ~$70 USD/mes
- Rendimiento bruto inversor: ~9% anual
- Fee Sunstake (7%): ~$6,300 MXN por proyecto en 36 meses

---

## 4. User Stories & Acceptance Criteria

### MÓDULO 1 — Onboarding & Autenticación

---

#### US-001: Registro y autenticación biométrica

**Como** usuario nuevo de Sunstake (beneficiario o inversor),
**Quiero** registrarme con mi correo y activar Face ID / Touch ID,
**Para** acceder de forma segura sin recordar contraseñas.

**Acceptance Criteria:**
- [ ] AC1: El flujo de registro solicita solo email y nombre completo (≤3 pantallas)
- [ ] AC2: Face ID / Touch ID se activa en el primer login exitoso
- [ ] AC3: Una wallet embebida (Privy SDK) se genera automáticamente sin mostrar seed phrase al usuario
- [ ] AC4: El usuario selecciona su rol (Beneficiario / Inversor) al final del onboarding
- [ ] AC5: El tiempo total de onboarding es <90 segundos medidos en QA
- [ ] AC6: En dispositivos sin biometría, el fallback es PIN de 6 dígitos

**Notas técnicas:** Privy SDK maneja la custodia de la wallet. CryptoKit firma localmente. No se transmite la clave privada al servidor de Sunstake.

---

#### US-002: Selección de perfil post-registro

**Como** usuario que completó el registro,
**Quiero** ver claramente las dos rutas disponibles (Beneficiario / Inversor),
**Para** entender cuál es mi caso antes de avanzar.

**Acceptance Criteria:**
- [ ] AC1: La pantalla muestra dos cards con ilustración, título y descripción de 1 línea cada una
- [ ] AC2: El usuario puede cambiar de rol en Configuración (no es definitivo)
- [ ] AC3: El contenido posterior se adapta al rol seleccionado (no se mezclan flujos)

---

### MÓDULO 2 — Flujo Beneficiario

---

#### US-101: Calculadora IA de cuota ideal

**Como** beneficiario,
**Quiero** ingresar mi consumo eléctrico y ubicación y recibir una cuota mensual calculada por IA,
**Para** saber exactamente cuánto pagaré y si me conviene antes de comprometerme.

**Acceptance Criteria:**
- [ ] AC1: El formulario solicita: consumo mensual (kWh o monto en pesos), código postal o ubicación en mapa, plazo preferido (12 / 24 / 36 meses)
- [ ] AC2: La IA usa NASA POWER API para obtener horas de sol de la zona (dato real, no estimado)
- [ ] AC3: El resultado muestra la cuota en MXN con desglose visible de 4 variables: consumo, radiación solar, tamaño del panel, plazo
- [ ] AC4: Se muestra texto en lenguaje natural generado con Foundation Models (on-device): *"Tu cuota es $850 MXN/mes porque consumes 320 kWh/mes en una zona con 5.2h de sol al día..."*
- [ ] AC5: Se muestra barra de confianza del cálculo: Alta / Media / Baja según calidad de datos
- [ ] AC6: El tiempo de cálculo es <5 segundos en condiciones normales de red
- [ ] AC7: Si NASA POWER API falla, se usa promedio regional de fallback y se indica al usuario

**Notas técnicas:** El modelo de cuota corre on-device con Core ML. Foundation Models genera la explicación en lenguaje natural. No se envían datos al servidor de Sunstake para el cálculo.

---

#### US-102: Override manual de plazo y monto

**Como** beneficiario que vio la cuota calculada,
**Quiero** poder ajustar el plazo (12, 24, 36 meses) y ver cómo cambia la cuota en tiempo real,
**Para** tomar la decisión que mejor se adapte a mis posibilidades, no la que la IA eligió.

**Acceptance Criteria:**
- [ ] AC1: Slider o segmented control para cambiar el plazo actualiza la cuota en <500ms (on-device, sin red)
- [ ] AC2: El desglose se recalcula y actualiza con cada cambio de plazo
- [ ] AC3: El usuario puede ingresar un monto de cuota máximo y el sistema sugiere el plazo correspondiente
- [ ] AC4: Existe un botón prominente "Ajustar mi propuesta" antes del CTA de publicación
- [ ] AC5: La IA nunca bloquea el override — el usuario siempre puede modificar

**Criterio HCAI:** Este feature es el componente de Control humano más crítico del flujo.

---

#### US-103: Publicación del proyecto como Smart Contract

**Como** beneficiario que aceptó su cuota,
**Quiero** publicar mi proyecto en la plataforma y que quede registrado en blockchain,
**Para** que los inversores puedan financiarlo y yo empiece a recibir la instalación.

**Acceptance Criteria:**
- [ ] AC1: Pantalla de resumen muestra: cuota, plazo, monto total a financiar, rendimiento ofrecido al inversor, fee de Sunstake
- [ ] AC2: Requiere confirmación explícita con Face ID / Touch ID antes de publicar
- [ ] AC3: Al confirmar, se despliega `SolarProject.sol` en Base Sepolia (testnet en demo) y se emiten los tokens ERC-1155
- [ ] AC4: El usuario ve un loader con estado: "Creando contrato...", "Emitiendo tokens...", "¡Proyecto publicado!"
- [ ] AC5: El hash de la transacción de creación es visible y tiene link a Basescan
- [ ] AC6: Si la transacción falla, se muestra error específico y opción de reintentar (sin cobrar gas dos veces)

---

#### US-104: Dashboard de propiedad progresiva

**Como** beneficiario con proyecto activo,
**Quiero** ver en tiempo real qué porcentaje del panel ya es mío,
**Para** mantener la motivación y saber cuánto me falta para ser dueño completo.

**Acceptance Criteria:**
- [ ] AC1: Indicador visual circular (progress ring) que muestra % de tokens adquiridos
- [ ] AC2: Datos mostrados: % propiedad actual, meses pagados / meses totales, próximo pago (fecha y monto), ahorro acumulado vs. CFE estimado
- [ ] AC3: Historial de pagos con fecha, monto en MXN y USDC, y hash de transacción con link a Basescan
- [ ] AC4: Sección "Tu panel" muestra ubicación, tamaño (kW), generación estimada
- [ ] AC5: Los datos se actualizan al abrir la app (pull-to-refresh disponible)
- [ ] AC6: Cuando el beneficiario llega a 100%, aparece banner celebratorio: "¡El panel es tuyo!" con hash de transferencia de propiedad

---

#### US-105: Notificación de pago confirmado

**Como** beneficiario,
**Quiero** recibir una notificación cuando mi pago mensual quede registrado en blockchain,
**Para** tener certeza sin tener que abrir la app constantemente.

**Acceptance Criteria:**
- [ ] AC1: Push notification se envía dentro de los 60 segundos posteriores a la confirmación on-chain
- [ ] AC2: La notificación incluye: monto, fecha, y texto "Verificado en blockchain"
- [ ] AC3: Al tocar la notificación, la app abre directamente al historial de pagos con el nuevo pago destacado
- [ ] AC4: Si el usuario desactiva notificaciones, hay badge visible en el ícono de la app

---

### MÓDULO 3 — Flujo Inversor

---

#### US-201: Explorador de proyectos

**Como** inversor,
**Quiero** explorar proyectos disponibles con información de impacto, rendimiento y riesgo,
**Para** elegir en cuáles invertir de forma informada.

**Acceptance Criteria:**
- [ ] AC1: Lista de proyectos muestra por card: ciudad/estado, rendimiento anual esperado (%), plazo restante, % financiado, CO₂ evitado estimado (ton/año), monto mínimo para invertir
- [ ] AC2: Filtros disponibles: región (estado), rendimiento mínimo, plazo restante, % financiado (para diversificación)
- [ ] AC3: Cada card tiene indicador visual de nivel de financiamiento (progress bar)
- [ ] AC4: Proyectos 100% financiados están marcados como "Cerrado" y no permiten inversión
- [ ] AC5: El explorador carga los primeros 10 proyectos en <2 segundos; paginación infinita
- [ ] AC6: Sin conexión, muestra caché local con timestamp de última actualización

---

#### US-202: Compra de fracciones (tokens ERC-1155)

**Como** inversor que eligió un proyecto,
**Quiero** comprar fracciones del mismo con confirmación paso a paso,
**Para** invertir con confianza sabiendo exactamente qué estoy comprando y cuánto pago.

**Acceptance Criteria:**
- [ ] AC1: Flujo de compra en 3 pasos claramente indicados: 1) Elegir monto → 2) Revisar detalles → 3) Confirmar
- [ ] AC2: Paso 1: Slider o input de monto en USDC con mínimo $1 USD; muestra equivalente en tokens y rendimiento mensual estimado
- [ ] AC3: Paso 2: Resumen completo: tokens a recibir, rendimiento mensual estimado, gas fee estimado, dirección del contrato, link a Basescan
- [ ] AC4: Paso 3: Confirmación con Face ID / Touch ID
- [ ] AC5: Transacción procesada en Base Network; loader con estado visible
- [ ] AC6: Al confirmar, el hash de transacción es visible con link a Basescan
- [ ] AC7: El gas fee se muestra en USD y MXN antes de confirmar (nunca sorpresas)
- [ ] AC8: Si el balance USDC es insuficiente, se muestra mensaje claro con opción de recarga (instrucciones, no compra automática)

---

#### US-203: Historial de rendimientos

**Como** inversor con proyectos activos,
**Quiero** ver el historial de rendimientos recibidos con hash de cada transacción,
**Para** verificar independientemente que mi dinero llegó.

**Acceptance Criteria:**
- [ ] AC1: Lista de rendimientos recibidos con: fecha, monto en USDC y MXN, proyecto origen, hash de transacción
- [ ] AC2: Cada ítem tiene botón "Ver en Basescan" que abre el explorer en Safari
- [ ] AC3: Resumen en la cabecera: rendimiento total recibido (mes actual / acumulado), tasa anualizada real vs. esperada
- [ ] AC4: Opción de exportar historial como CSV (para declaración fiscal)
- [ ] AC5: Si hay meses sin rendimiento (beneficiario no pagó), se indica claramente el estado del proyecto

---

#### US-204: Notificación de rendimiento recibido

**Como** inversor,
**Quiero** recibir una notificación cuando recibo mi rendimiento mensual,
**Para** saberlo sin tener que abrir la app.

**Acceptance Criteria:**
- [ ] AC1: Push notification dentro de los 60 segundos de la distribución on-chain
- [ ] AC2: Notificación muestra: monto, proyecto origen, texto "Verificado en blockchain"
- [ ] AC3: Tap en notificación abre directamente al historial con el nuevo rendimiento destacado

---

### MÓDULO 4 — Compartido

---

#### US-301: Visualización del contrato inteligente activo

**Como** usuario de Sunstake (cualquier rol),
**Quiero** ver los datos del Smart Contract del proyecto en el que participo,
**Para** poder verificar por mí mismo sin depender de Sunstake.

**Acceptance Criteria:**
- [ ] AC1: Se muestra: dirección del contrato, red (Base Sepolia / Base Mainnet), estado (activo/completado), plazo y fecha de inicio
- [ ] AC2: Botón "Ver en Basescan" abre el contrato en el explorer
- [ ] AC3: Para inversores: muestra sus tokens en posesión vs. total emitido
- [ ] AC4: El dato se obtiene directamente del RPC de Base Network, no de una base de datos de Sunstake

---

#### US-302: Configuración de cuenta y seguridad

**Como** usuario,
**Quiero** gestionar mi cuenta, cambiar preferencias y ver el estado de mi wallet,
**Para** mantener el control sobre mi información y seguridad.

**Acceptance Criteria:**
- [ ] AC1: Sección "Mi Wallet": dirección de wallet (copyable), balance USDC, opción de desconectar wallet
- [ ] AC2: Sección "Seguridad": estado de Face ID / Touch ID, opción de cambiar a PIN
- [ ] AC3: Sección "Notificaciones": toggles por tipo (pagos, rendimientos, actualizaciones)
- [ ] AC4: Opción "Eliminar cuenta" que requiere confirmación de 2 pasos y advierte sobre fondos pendientes
- [ ] AC5: No se muestra seed phrase ni clave privada en ningún momento dentro de la app

---

## 5. UI/UX Requirements

### 5.1 Principios de Diseño

| Principio | Implementación |
|-----------|---------------|
| **Cero jerga crypto** | "Tu participación en el proyecto" no "tus tokens ERC-1155" |
| **Progresividad** | La complejidad blockchain es invisible hasta que el usuario la pide ver |
| **Confirmación explícita** | Todo flujo financiero tiene un paso de revisión antes del CTA final |
| **Estado siempre visible** | El usuario nunca se pregunta "¿qué pasó?" — hay loader + resultado siempre |

### 5.2 Design System

- **Framework:** SwiftUI con componentes nativos iOS
- **Tipografía:** SF Pro (sistema iOS), nunca fuentes externas
- **Modo oscuro:** Soporte nativo, preferencia del sistema
- **Accesibilidad:**
  - Dynamic Type en todos los textos (mínimo `.body`, preferido `.title3`)
  - VoiceOver labels en todos los elementos interactivos
  - Contraste WCAG AA mínimo (4.5:1)
  - Soporte para reduce motion en animaciones

### 5.3 User Flows

#### Flow A — Beneficiario: Primera cuota

```
Splash → Onboarding (3 pantallas) → Selección de rol (Beneficiario)
    → Formulario de datos (consumo + ubicación + plazo)
    → Pantalla de cálculo IA (loader < 5s)
    → Resultado con desglose visible
        → [Override] Ajustar plazo → Recálculo instantáneo
        → [Confirmar] Pantalla de resumen completo
            → [Face ID] → Loader ("Creando contrato...")
                → Éxito: Dashboard con hash + link Basescan
                → Error: Mensaje específico + Reintentar
```

#### Flow B — Inversor: Primera inversión

```
Onboarding → Selección de rol (Inversor)
    → Explorador de proyectos (lista con filtros)
    → Detalle de proyecto (métricas + contrato)
        → [Invertir] Paso 1: Seleccionar monto
            → Paso 2: Resumen (tokens + rendimiento + gas fee)
                → [Face ID] Paso 3: Confirmación
                    → Loader ("Procesando en Base Network...")
                        → Éxito: Hash + link Basescan + rendimiento esperado
                        → Error: Mensaje + Reintentar
```

#### Flow C — Beneficiario: Pago mensual recurrente

```
Notificación push → App abre en Dashboard
    → Botón "Pagar cuota de [mes]" con monto y fecha
        → Resumen del pago (monto USDC + gas fee estimado)
            → [Face ID] Confirmación
                → Loader
                    → Éxito: Hash + % de propiedad actualizado
```

### 5.4 Wireframes por Pantalla (Descripción)

#### W-01: Calculadora IA (pantalla principal del beneficiario)

```
┌─────────────────────────────────┐
│  ☀️  Sunstake                    │
├─────────────────────────────────┤
│  Calcula tu cuota solar          │
│                                 │
│  ¿Cuánto pagas de luz al mes?   │
│  [        $1,200 MXN        ▼]  │
│                                 │
│  ¿Dónde está tu casa?           │
│  [  📍 Guadalajara, JAL      ]  │
│                                 │
│  Plazo de pago                  │
│  [ 12 ] [ 24 ] [●36] meses      │
│                                 │
│  ┌──────────────────────────┐   │
│  │ ✅ Confianza: Alta        │   │
│  │                          │   │
│  │ Tu cuota: $850 MXN/mes   │   │
│  │                          │   │
│  │ • 320 kWh/mes            │   │
│  │ • 5.2h sol/día (NASA)    │   │
│  │ • Panel 2kW              │   │
│  │ • 87% cobertura de CFE   │   │
│  └──────────────────────────┘   │
│                                 │
│  [  Ajustar propuesta  ]        │
│  [  Publicar proyecto  ] ←CTA   │
└─────────────────────────────────┘
```

#### W-02: Dashboard Beneficiario (propiedad progresiva)

```
┌─────────────────────────────────┐
│  Mi Panel Solar                 │
├─────────────────────────────────┤
│        ╭──────────╮             │
│        │   34%    │             │
│        │  tuyo    │             │
│        ╰──────────╯             │
│                                 │
│  12 de 36 meses pagados         │
│  Próximo pago: 15 Jun • $850    │
│                                 │
│  Ahorro acumulado: $4,800 MXN   │
│  vs. CFE este año               │
│                                 │
│  ─── Historial de pagos ───     │
│  Mayo 15  $850  [0x3f4a...] 🔗  │
│  Abr 15   $850  [0x2b9c...] 🔗  │
│  Mar 15   $850  [0x1d7e...] 🔗  │
│                                 │
│  [ Pagar cuota de Junio ]       │
└─────────────────────────────────┘
```

#### W-03: Explorador de Proyectos (Inversor)

```
┌─────────────────────────────────┐
│  Proyectos disponibles    🔍 ≡  │
├─────────────────────────────────┤
│  Filtros: [Región ▼] [Plazo ▼] │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 🏠 Guadalajara, JAL        │  │
│  │ Rendimiento: 9.2% anual   │  │
│  │ Plazo: 36 meses           │  │
│  │ ████████░░ 78% financiado │  │
│  │ 🌱 1.2 ton CO₂/año        │  │
│  │ Desde $1 USD              │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 🏠 Monterrey, NL          │  │
│  │ Rendimiento: 8.7% anual   │  │
│  │ Plazo: 24 meses           │  │
│  │ ████░░░░░░ 45% financiado │  │
│  │ 🌱 0.9 ton CO₂/año        │  │
│  │ Desde $1 USD              │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

#### W-04: Confirmación de compra (Inversor — Paso 2)

```
┌─────────────────────────────────┐
│  ← Revisar inversión            │
├─────────────────────────────────┤
│  Paso 2 de 3                   │
│  ○──●──○                       │
│                                 │
│  Proyecto: Guadalajara, JAL     │
│  Tokens: 50 fracciones          │
│  Monto: $50 USDC                │
│                                 │
│  Rendimiento mensual: ~$0.38    │
│  Rendimiento anual: ~$4.60      │
│  Tasa efectiva: ~9.2%           │
│                                 │
│  Gas fee estimado: $0.02 USD    │
│                                 │
│  ─── Contrato ─────────────    │
│  0x7f3a...b2c4  [Ver en Base] 🔗│
│  Red: Base Sepolia (demo)       │
│                                 │
│  [ Cancelar ]  [ Confirmar ]   │
└─────────────────────────────────┘
```

---

## 6. Technical Requirements

### 6.1 Stack iOS

| Tecnología | Versión Mínima | Uso | Justificación HCAI |
|------------|---------------|-----|--------------------|
| **SwiftUI** | iOS 16 | UI de ambos flujos | Accesibilidad nativa, Dynamic Type |
| **Core ML** | iOS 16 | Modelo de cálculo de cuota on-device | Privacidad: datos no salen del dispositivo |
| **Foundation Models** | iOS 18 | Explicación IA en lenguaje natural on-device | Interpretabilidad: desglose comprensible |
| **SwiftData** | iOS 17 | Persistencia: historial, favoritos, perfil | Disponibilidad offline |
| **CryptoKit** | iOS 13 | Firma de transacciones, seguridad local | Seguridad sin exponer claves |
| **LocalAuthentication** | iOS 8 | Face ID / Touch ID | Control humano: confirmación biométrica |

**Versión mínima soportada:** iOS 16 (compatible con iPhone SE 3ra gen)
**Nota Foundation Models:** Feature flag si el dispositivo es iOS <18; mostrar desglose textual estático como fallback.

### 6.2 APIs Externas (públicas y gratuitas)

| API | Endpoint | Uso | Rate Limit | Fallback |
|-----|----------|-----|-----------|---------|
| **NASA POWER API** | `https://power.larc.nasa.gov/api/temporal/daily/point` | Radiación solar por lat/lon | Sin límite documentado | Promedios regionales hardcoded por estado |
| **Base Network RPC** | `https://mainnet.base.org` / `https://sepolia.base.org` | Lectura de contratos, envío de tx | 10 req/s (público) | Alchemy backup RPC |
| **Basescan API** | `https://api.basescan.org/api` | Verificación de transacciones, historial | 5 req/s free | Cache local |

### 6.3 Blockchain

| Componente | Especificación |
|------------|---------------|
| **Red (Demo)** | Base Sepolia Testnet (chain ID: 84532) |
| **Red (Producción)** | Base Mainnet (chain ID: 8453) |
| **Estándar de token** | ERC-1155 (multi-token, cada proyecto es una colección) |
| **Moneda** | USDC on Base (`0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`) |
| **Wallet SDK** | Privy SDK (wallet embebida, sin seed phrase visible al usuario) |

#### Smart Contracts

```
SolarProject.sol
├── Almacena: cuota, plazo, beneficiario address, rendimiento esperado, metadata
├── ERC-1155: emite tokens fraccionados por proyecto
└── Función: publishProject(), getProjectMetadata()

FractionToken.sol
├── Extiende ERC-1155 de SolarProject.sol
└── Función: mint(), balanceOf(), totalSupply()

PaymentSplitter.sol
├── Recibe pago mensual del beneficiario
├── Calcula pro-rata de cada inversor
├── Retiene fee de plataforma (5-8%)
└── Función: receivePayment(), distributeYield(), getPlatformFee()

OwnershipTransfer.sol
├── Se activa cuando beneficiario completa el plazo
├── Quema tokens de todos los inversores
└── Función: completeProject(), burnInvestorTokens(), transferOwnership()
```

**Red flags contractuales para el demo:**
- Usar Base Sepolia exclusivamente
- Tener contratos verificados en Basescan Sepolia
- No manejar fondos reales en la presentación

### 6.4 Modelo Core ML — Calculadora de Cuota

**Input features:**
```
- consumo_kwh: Float (consumo mensual en kWh)
- horas_sol: Float (horas de sol promedio de NASA POWER)
- precio_panel_instalacion: Float (catálogo interno, en MXN)
- plazo_meses: Int (12, 24, 36)
- inflacion_estimada: Float (constante: 0.048)
```

**Output:**
```
- cuota_mensual: Float (en MXN)
- cobertura_porcentaje: Float (% del consumo CFE cubierto)
- rendimiento_inversor: Float (% anual proyectado)
- confianza: Enum { alta, media, baja }
```

**Entrenamiento:** Usar datos históricos de instalaciones en México (CRE, ANES). Si no disponibles para hackathon, modelo lineal calibrado manualmente con 5 casos reales.

### 6.5 Constraints y Reglas de Negocio

| Constraint | Regla |
|-----------|-------|
| Monto mínimo de inversión | $1 USD en USDC |
| Monto máximo por inversor por proyecto | $10,000 USD (KYC simplificado) |
| Plazos disponibles | 12, 24, 36 meses únicamente |
| Moneda | Solo USDC on Base en MVP |
| Red | Solo Base Network (Sepolia en demo) |
| Gas fee máximo aceptable | Si estimado >$0.50 USD, advertir al usuario |
| Proyectos por beneficiario | Solo 1 proyecto activo simultáneo en MVP |
| Override IA | Siempre disponible, nunca puede bloquearse |

### 6.6 Seguridad y Privacidad

- La clave privada de la wallet **nunca** abandona el Secure Enclave del dispositivo
- El cálculo de cuota se realiza **exclusivamente on-device** (Core ML)
- La explicación en lenguaje natural se genera **on-device** (Foundation Models)
- Los datos de consumo eléctrico **no se almacenan** en servidores de Sunstake
- Face ID / Touch ID requerido para **toda transacción financiera**
- La wallet embebida (Privy) no expone seed phrase en la app

---

## 7. HCAI Compliance Checklist

> Cada feature debe pasar esta verificación antes de darse por completa.

| Principio HCAI | Pregunta de verificación | Feature que lo implementa |
|---------------|------------------------|--------------------------|
| **Explicabilidad** | ¿Se puede explicar cómo y por qué la IA tomó la decisión? | US-101: Desglose visible de 4 variables + texto Foundation Models |
| **Control humano** | ¿El usuario puede anular o modificar la decisión de la IA? | US-102: Override manual de plazo y monto |
| **Transparencia de datos** | ¿El usuario sabe qué datos se usaron? | US-101: Fuente NASA POWER visible en el desglose |
| **Confianza verificable** | ¿El resultado es verificable independientemente? | US-301: Hash en Basescan, contrato auditable |
| **Carga cognitiva** | ¿El usuario tiene que pensar demasiado? | Flujos lineales separados, sin terminología blockchain en UI |
| **Equidad e inclusividad** | ¿Funciona para usuarios sin experiencia crypto? | Privy wallet embebida, sin seed phrases, sin jerga |
| **Privacidad** | ¿Los datos sensibles permanecen en el dispositivo? | Core ML on-device, Foundation Models on-device |
| **Diseño responsable** | ¿Hay protecciones contra comportamiento nocivo? | Confirmación biométrica en toda transacción, sin auto-pagos |
| **Sustentabilidad** | ¿El impacto técnico y ambiental es positivo? | Base L2 (bajo gas), modelo on-device (bajo cómputo en nube) |
| **Interpretabilidad** | ¿Los pasos intermedios son visibles? | Loader con estados, hash de cada tx, desglose de cuota |

**Criterio de aprobación:** Los 10 principios deben estar implementados. Si alguno falta, la feature está incompleta para el hackathon.

---

## 8. Success Metrics

### 8.1 KPIs de Experiencia (Demo / Hackathon)

| KPI | Meta | Cómo Medirlo |
|-----|------|-------------|
| Tiempo en flujo Beneficiario (onboarding → cuota) | < 3 minutos | Cronómetro en sesión de prueba |
| Tiempo en flujo Inversor (onboarding → inversión) | < 2 minutos | Cronómetro en sesión de prueba |
| % de usuarios que entienden el desglose IA sin ayuda | > 80% | Pregunta post-task en prueba de usuario |
| % de usuarios que encuentran el hash de transacción | > 90% | Observación en sesión de prueba |
| Tasa de éxito en primera transacción | > 95% | Logs de transacciones en testnet |
| Tiempo de cálculo IA (on-device) | < 5 segundos | XCTest performance test |

### 8.2 KPIs Técnicos (Demo)

| KPI | Meta |
|-----|------|
| Contratos desplegados en Base Sepolia | ≥ 1 proyecto activo con ≥ 3 inversores simulados |
| Pagos mensuales procesados en testnet | ≥ 2 ciclos completos antes de la demo |
| Tiempo de confirmación de tx en Base Sepolia | < 5 segundos |
| Crash rate en demo | 0 crashes |
| Cobertura de accesibilidad VoiceOver | 100% elementos interactivos con label |

### 8.3 KPIs de Rúbrica del Hackathon (Proyección)

| Categoría | Peso | Puntaje Esperado | Estrategia |
|-----------|------|-----------------|------------|
| Fit Problema–Solución | 40% | 36–40/40 | Pitch con datos reales de CFE + caso real de Ana |
| HCAI | 30% | 27–30/30 | Checklist completo, demostrar override + desglose en vivo |
| Implementación Técnica | 30% | 25–30/30 | Demo en simulador + Foundation Models en vivo |
| **Total** | 100% | **88–100/100** | |

### 8.4 KPIs de Negocio (Post-hackathon, 6 meses)

| KPI | Meta |
|-----|------|
| Proyectos publicados | 10 proyectos reales en Base Mainnet |
| Inversores activos | 100 wallets con al menos 1 inversión |
| TVL (Total Value Locked) | $10,000 USD en USDC |
| Rendimiento pagado a inversores | 100% de distribuciones sin retraso |
| NPS de beneficiarios | > 60 |

---

## 9. Implementation Roadmap

### Phase 0 — Setup (Día 1, 2h)

| Tarea | Responsable | Criterio de Done |
|-------|-------------|-----------------|
| Crear proyecto Xcode con SwiftUI + SwiftData | Dev | Proyecto compila sin errores |
| Configurar Privy SDK (wallet embebida) | Dev | Login con email funcional en simulador |
| Desplegar contratos en Base Sepolia | Smart Contract Dev | Addresses verificadas en Basescan Sepolia |
| Configurar NASA POWER API call | Dev | Retorna datos de radiación para CP de prueba |

### Phase 1 — Core Beneficiario (Días 1–2, 8h)

**Prioridad:** MVP crítico. Sin esto no hay demo.

| Tarea | US | Story Points |
|-------|-----|-------------|
| Formulario de datos (consumo + ubicación + plazo) | US-101 | 3 |
| Integración NASA POWER API + fallback | US-101 | 2 |
| Modelo Core ML de cuota (versión lineal) | US-101 | 3 |
| Pantalla de resultado con desglose visible | US-101 | 2 |
| Slider de override de plazo con recálculo | US-102 | 2 |
| Pantalla de resumen + confirmación biométrica | US-103 | 2 |
| Despliegue de SolarProject.sol desde la app | US-103 | 3 |
| Dashboard de propiedad progresiva (% ring) | US-104 | 3 |

**Total Phase 1:** ~20 Story Points

### Phase 2 — Core Inversor (Días 2–3, 8h)

**Prioridad:** MVP crítico. Necesario para demo completa.

| Tarea | US | Story Points |
|-------|-----|-------------|
| Explorador de proyectos (lista + cards) | US-201 | 3 |
| Filtros básicos (región, rendimiento) | US-201 | 2 |
| Flujo de compra 3 pasos | US-202 | 3 |
| Integración con Base Network RPC para compra | US-202 | 3 |
| Confirmación biométrica en compra | US-202 | 1 |
| Historial de rendimientos + links Basescan | US-203 | 2 |

**Total Phase 2:** ~14 Story Points

### Phase 3 — HCAI Polish (Día 3, 4h)

**Prioridad:** Diferenciador en rúbrica del hackathon.

| Tarea | US | Story Points |
|-------|-----|-------------|
| Foundation Models: texto explicativo on-device | US-101 | 3 |
| Barra de confianza del cálculo (Alta/Media/Baja) | US-101 | 1 |
| Visualización del contrato activo + Basescan link | US-301 | 2 |
| VoiceOver labels en todos los elementos | Shared | 2 |
| Dynamic Type en todos los textos | Shared | 1 |
| Loader states descriptivos en transacciones | US-103, US-202 | 2 |

**Total Phase 3:** ~11 Story Points

### Phase 4 — Notificaciones y Pulido (Día 4, 4h)

**Prioridad:** Deseable. Si el tiempo lo permite.

| Tarea | US | Story Points |
|-------|-----|-------------|
| Push notifications (pago confirmado) | US-105 | 3 |
| Push notifications (rendimiento recibido) | US-204 | 2 |
| Onboarding (3 pantallas) + selección de rol | US-001, US-002 | 3 |
| Exportar historial CSV | US-203 | 2 |
| Dark mode testing | Shared | 1 |

**Total Phase 4:** ~11 Story Points

### Phase 5 — Demo Prep (Día 4, 2h)

| Tarea | Criterio |
|-------|---------|
| Poblar Base Sepolia con 3–5 proyectos de demo | Proyectos visibles en explorador |
| Simular 2 ciclos de pago mensual | Historial visible en ambos flujos |
| Test de flujo completo en simulador | Sin crashes, <3 min beneficiario, <2 min inversor |
| Preparar KeyNote con stack y demo points | Entregable hackathon completo |
| Ensayo del pitch (10 min) | Override + desglose IA demostrado en vivo |

---

## 10. Apéndice & Glosario

### Glosario Técnico → Lenguaje de Usuario

| Término Técnico | Cómo aparece en la app |
|----------------|----------------------|
| ERC-1155 token | "Tu participación en el proyecto" |
| Smart Contract | "Contrato registrado en blockchain" |
| USDC | "Dólares digitales estables" |
| Base Network | "Red de pagos verificables" |
| Hash de transacción | "Código de verificación" |
| Wallet | "Tu cuenta de pagos" |
| Gas fee | "Costo de procesamiento" |
| Base Sepolia | "Modo de prueba" |

### Dependencias Críticas

| Dependencia | Tipo | Riesgo | Mitigación |
|------------|------|--------|------------|
| Privy SDK (wallet embebida) | Externo | Medio | Evaluar WalletConnect como alternativa |
| Foundation Models (iOS 18) | Apple | Alto | Feature flag + fallback a texto estático |
| NASA POWER API disponibilidad | Externo | Bajo | Cache local + promedios regionales hardcoded |
| Base Sepolia estabilidad | Blockchain | Medio | Alchemy RPC backup |
| Core ML modelo de cuota | Interno | Alto | Versión lineal calibrada manualmente como V1 |

### Contratos de Referencia (Base Sepolia)

- USDC on Base Sepolia (demo): `0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f` — TestnetERC20 (6 decimales). Faucet con mint generoso: https://staging.aave.com/faucet (selecciona Base Sepolia).
- Base Sepolia Explorer: `https://sepolia.basescan.org`
- Base Sepolia RPC: `https://sepolia.base.org`

### Checklist de Entregables del Hackathon

- [ ] Código de App en iCloud (link compartido antes de la hora límite)
- [ ] Keynote con: título, propósito, necesidad, integrantes, universidad, lab manager, tecnologías, repositorios
- [ ] Demo funcional en simulador Xcode (flujo completo beneficiario + inversor)
- [ ] Lista de tecnologías: SwiftUI, Core ML, Foundation Models, SwiftData, CryptoKit, LocalAuthentication, Base Network, ERC-1155, USDC, Privy SDK, NASA POWER API, Basescan API

---

*PRD generado para Swift Changemakers Hackathon 2026 — Human Centered AI*
*Versión 1.0 | Sunstake Team | Mayo 2026*
*Stack: SwiftUI · Core ML · Foundation Models · Base Network · ERC-1155 · USDC · Privy*
