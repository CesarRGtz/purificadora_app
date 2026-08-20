# Proveedores

Feature aislado con capas `domain`, `data` y `presentation`. La sucursal se
almacena como texto para no acoplar este catálogo al módulo de sucursales.

Los proveedores usan eliminación lógica mediante `deleted_at`; la aplicación
solo consulta registros activos. Cuando Supabase no está configurado se puede
usar `Probar sin conexión` para validar todo el CRUD con datos temporales.

La estructura de Supabase se encuentra en
`supabase/migrations/20260820010000_create_suppliers_and_soft_delete_companies.sql`.
