# Empresas

Feature aislado con capas `domain`, `data` y `presentation` para administrar los
datos fiscales de las empresas.

## Supabase

1. Aplica `supabase/migrations/20260820000000_create_companies.sql` al proyecto.
2. Ejecuta Flutter sin guardar credenciales en el repositorio:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://<proyecto>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

También se admite `SUPABASE_ANON_KEY` para proyectos que todavía usan la llave
anónima heredada.

Las políticas RLS solo permiten operaciones al rol `authenticated`. La llave
`service_role` nunca debe usarse en la aplicación cliente.

## Prueba sin conexión

Cuando Supabase no está configurado, la pantalla de configuración ofrece
`Probar sin conexión`. Este modo usa un repositorio en memoria con un registro
de ejemplo y permite probar altas, cambios, búsquedas y eliminaciones. Sus datos
son temporales y se pierden al cerrar la aplicación.

## Eliminación lógica

Eliminar una empresa establece `deleted_at` y la oculta de las consultas
normales; no se ejecuta un `DELETE` físico. La migración complementaria
`20260820010000_create_suppliers_and_soft_delete_companies.sql` actualiza
instalaciones donde la tabla de empresas ya existía.
