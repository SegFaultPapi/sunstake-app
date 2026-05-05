# Login wallet embebida: E2E + HCAI

## Alcance

- Entorno: Base Sepolia (`chainId 84532`)
- Objetivo: acceso sin friccion cripto con wallet embebida y confirmacion humana en operaciones financieras

## Pruebas E2E criticas

1. Onboarding completado -> pantalla de acceso visible.
2. Login por correo:
   - ingresar email valido,
   - enviar codigo,
   - ingresar OTP de 6 digitos,
   - verificar sesion activa y wallet creada.
3. Registro nuevo:
   - nombre + email + PIN 6 digitos,
   - verificar wallet embebida creada automaticamente.
4. Pantalla de cuenta:
   - direccion wallet visible en formato corto,
   - proveedor de wallet visible,
   - red activa: Base Sepolia.
5. Publicar proyecto:
   - estados loader visibles,
   - hash de transaccion retornado.
6. Comprar fracciones:
   - estado de procesamiento,
   - hash de transaccion retornado.
7. Pagar cuota:
   - estado de procesamiento,
   - pago agregado al historial con hash.
8. Error de red:
   - forzar fallo RPC,
   - mensaje humano sin codigo tecnico.
9. Red incorrecta:
   - simular chain id distinto a 84532,
   - bloqueo con mensaje claro.
10. Cierre de sesion:
    - limpiar wallet local y volver a auth.

## Checklist HCAI para release demo

- Control humano:
  - cada transaccion mantiene confirmacion explicita.
- Interpretabilidad:
  - lenguaje UI sin jerga cripto en pantallas primarias.
- Inclusividad:
  - flujo principal funciona sin conocimiento blockchain.
- Privacidad:
  - sin seed phrase mostrada en UI.
- Carga cognitiva:
  - acceso en pocos pasos, textos simples.
- Confianza verificable:
  - hash visible despues de acciones financieras.
- Transparencia:
  - red y estado de wallet visibles en seccion de cuenta.

## Criterios de salida

- 100% de las pruebas E2E criticas pasan en simulador.
- Sin crashes en flujo onboarding -> login -> transaccion.
- Tiempo total de acceso <= 90 segundos en pruebas internas.
