# Sucursales y productos

Feature aislado con Clean Architecture para administrar sucursales, un catálogo
de productos y la disponibilidad específica de productos por sucursal.

- Sucursal: nombre, negocio, dirección, latitud y longitud.
- Producto: nombre, SKU, descripción y precio base.
- La relación sucursal-producto permite que cada ubicación tenga un catálogo
  distinto.
- Las tres tablas usan eliminación lógica con `deleted_at`.
- Incluye un modo local para probar todo el flujo sin Supabase.

`negocio` se almacena como texto para evitar acoplar este feature a Empresas.
El catálogo también permanece separado de `AppState`, POS e Inventario para no
modificar módulos que pueden estar desarrollándose en paralelo.

Proveedores conserva por ahora `branch_name` como texto; renombrar una sucursal
no modifica automáticamente los proveedores existentes. Esta separación es
intencional para no generar cambios cruzados en ese feature.
