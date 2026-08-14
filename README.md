# ERP Purificadora - Sistema de Gestión Integral

Este es un sistema completo (ERP) desarrollado en **Flutter** diseñado específicamente para la administración, operación y control de Purificadoras de Agua.

Actualmente, el sistema se encuentra en su **Fase de Demostración**, funcionando con un estado local (en memoria) que permite navegar por todos los módulos, realizar transacciones y ver el comportamiento del sistema sin necesidad de conexión a una base de datos externa.

## 🚀 Módulos Principales

1. **📊 Dashboard y Administración**
   - Vista general de métricas en tiempo real.
   - Accesos rápidos a los módulos más utilizados.
   - Resumen de ingresos, rutas activas e inventario crítico.

2. **💰 Punto de Venta (POS)**
   - Catálogo de productos con imágenes y precios.
   - Cobro rápido en efectivo con cálculo de cambio.
   - Gestión de ventas a **Crédito** vinculadas a clientes.
   - Control de caja (Apertura, Corte, y movimientos manuales de ingresos/retiros).

3. **📦 Inventario y Compras**
   - Control de existencias de Producto Terminado (Garrafones) y Materias Primas (Tapas, Sellos Térmicos, Cloro).
   - Historial de compras y actualización de stock automático al marcar pedidos como "Recibidos".
   - Control de activos en comodato o préstamo.

4. **💧 Producción**
   - Bitácora de llenado de garrafones.
   - Registro de niveles de cloro residual (ppm) y lavado de filtros.
   - **Automatización:** Al registrar producción, se descuentan automáticamente las tapas y sellos del inventario y aumentan los garrafones llenos.

5. **🚚 Logística y Reparto**
   - Creación y asignación de rutas a choferes.
   - Interfaz simulada de "App de Repartidor" integrada.
   - Seguimiento del progreso de la ruta (Entregas completadas vs Totales).

6. **📈 Reportes**
   - Exportación de información clave a formato Excel (`.xlsx`).
   - Descarga de reportes financieros, de producción y logística para auditoría.

## 💻 Tecnologías Utilizadas

- **Framework:** Flutter (Soporte multiplataforma: Windows, Web, Android, iOS).
- **Estado Local:** `Provider` (La lógica de negocios está centralizada en `app_state.dart`).
- **Exportación a Excel:** Paquete `excel`.
- **Diseño Visual:** Tema claro corporativo (Blanco y Azul) con componentes modernos sin uso de librerías externas pesadas.

## ⚙️ Cómo ejecutar la Demostración

Dado que la aplicación almacena sus datos en memoria mediante `Provider`, cada vez que se inicie contará con información de prueba precargada, lista para ser demostrada a clientes.

1. Asegúrate de tener el entorno de Flutter configurado en tu máquina.
2. Abre una terminal en la raíz del proyecto (`purificadora_app`).
3. Instala las dependencias:
   ```bash
   flutter pub get
   ```
4. Ejecuta la aplicación (preferentemente en Windows o Web para la mejor experiencia de escritorio):
   ```bash
   flutter run -d windows
   ```
   *(o `flutter run -d chrome` para navegador web).*

## 🔮 Siguientes Pasos (Roadmap)

- **Integración con Supabase:** Migrar el `AppState` actual para conectarse a una base de datos PostgreSQL alojada en la nube (Supabase), permitiendo autenticación de usuarios, roles (Admin, Chofer) y persistencia real de los datos.
- **App Móvil de Repartidor Independiente:** Extraer el módulo de logística simulado en una aplicación independiente exclusiva para dispositivos Android/iOS de los choferes.
