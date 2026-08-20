# Inventario

Módulo aislado con arquitectura limpia para gestionar inventario por sucursal.
Reutiliza el catálogo real de `features/branches` y las tablas `branches`,
`products` y `branch_products`; no crea un catálogo paralelo.

## Categorías

- **Producto Terminado:** activos por sucursal con producto opcional, tipo,
  estado (`purchased`, `sold`, `loaned`, `returned`), cantidad y condición de
  venta.
- **Materia Prima:** insumos por sucursal, categoría, nombre, unidad y último
  costo. Sus cantidades se calculan desde movimientos auditables.
- **Productos:** CRUD del catálogo compartido, asignación a sucursales, receta
  de insumos por unidad y registro de producción/uso.

## Significado de columnas de materia prima

- `Ctd. compra`: suma de movimientos de compra.
- `Ctd. usados`: suma de consumos manuales y consumos generados por recetas.
- `Tras. entrada`: suma de entradas por traslado.
- `Tras. salida`: suma de salidas por traslado.
- `Existencia`: compra + traslado de entrada - usados - traslado de salida.
- `Últ. costo`: costo unitario de la compra o traslado de entrada más reciente.
- `Total`: valor estimado de la existencia usando ese último costo.

Los acumulados, la existencia y el total no se capturan manualmente para evitar
que se desincronicen del historial.

Los traslados seleccionan el mismo insumo y unidad en otra sucursal. La salida
y la entrada se guardan como una sola operación atómica; si no hay existencia
suficiente o el destino dejó de estar disponible, no se modifica ninguna de
las dos sucursales.

## Consumo de insumos

Un producto puede utilizar varias materias primas y una materia prima puede
formar parte de varios productos. La receta guarda la cantidad necesaria por
unidad y por sucursal. Al usar **Registrar producción / uso**, el repositorio
valida asignación, receta y existencias antes de descontar. En Supabase esto se
ejecuta mediante una RPC atómica; si falta un insumo no se aplica ningún cambio.
Compras, consumos y traslados incluyen una clave de operación idempotente para
que un reintento por una respuesta de red perdida no duplique movimientos.

La pantalla legacy de Producción no se modificó para evitar conflictos con ese
módulo. El punto explícito para aplicar la receta está en la categoría
**Productos** de Inventario.

## Persistencia

La migración `20260820030000_create_inventory.sql` agrega las tablas, RLS,
eliminado lógico, cascadas y RPC. Sin configuración de Supabase se puede usar el
modo local; las sucursales y productos locales se comparten con el apartado
Sucursales durante la ejecución de la aplicación.

Los saldos remotos se leen desde una vista agregada sobre el ledger completo y
las colecciones propias del módulo se cargan por páginas, evitando que el límite
de filas de PostgREST produzca existencias parciales.
