# Seed

Un archivo por área: `seed_areaN.sql`. Idempotente cuando sea posible (`ON CONFLICT DO NOTHING`). El seed del área 4 debe reproducir el ejemplo de cálculo de su `CONTEXTO.md` sección 10; el del área 3 debe tener mínimo 20 productos y 10 movimientos.

## Orden de carga

Cada seed de área va justo después de las migraciones de su área, en este orden: `seed_a00_base`, área 3, área 1, área 2, área 4, área 5 y área 6. Al final, después de `20260913_0800_a00_seguridad_anon`, va `seed_historico.sql`.

## Seed histórico (D-12)

`seed_historico.sql` es de la coordinación. Simula dos años de uso (sep 2024 a ago 2026) sin mover el stock final ni los ejemplos de los seeds de área:

- Parámetros legales y fiscales de 2024 y 2025 con su vigencia.
- 14 comercializadores nuevos (dos dados de baja) y un agente que se dio de baja en ago 2025.
- Compras mensuales en MXN y USD, unas 960 facturas cobradas o canceladas y conciliaciones trimestrales.
- Nóminas mensuales de oct 2024 a ago 2026 cerradas con separación de funciones, algunas con rechazo del gerente.
- Obligaciones de IVA, ISR, ISN y declaración anual cerradas de punta a punta, un pedimento por mes con compras en USD y licencias vencidas.
- Campañas externas y directas finalizadas (una cancelada) e investigaciones de mercado.

Tarda poco más de un minuto. Si ya existe la nómina de oct 2024 no hace nada. Después de cargarlo corre las siete suites de `supabase/tests/`.
