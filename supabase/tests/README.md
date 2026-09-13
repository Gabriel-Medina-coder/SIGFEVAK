# Pruebas SQL

Carpeta por área: `tests/areaN/`. Cada archivo indica qué RN verifica y falla con `RAISE EXCEPTION` si no se cumple. Ejemplo mínimo:

```sql
-- Verifica RN-A3-01: el stock no puede quedar negativo
DO $$
BEGIN
  BEGIN
    INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario) VALUES (1, 1, 999999, 1);
    RAISE EXCEPTION 'RN-A3-01 falló: se permitió stock negativo';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE 'RN-A3-01%' THEN RAISE; END IF;
  END;
END $$;
```
