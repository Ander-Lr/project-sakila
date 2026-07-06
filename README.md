# Sistema de Gestión de Alquiler de Películas

## Datos del Estudiante
- **Nombre del estudiante:** Anderson Lara
- **Nombre del proyecto:** Aplicación Distribuida Sakila

## Descripción de la Solución
Aplicación distribuida desarrollada para gestionar de manera segura el flujo completo de alquiler y devolución de películas. El sistema integra un backend en Spring Boot y un cliente web en Flutter, conectados a la base de datos MySQL Sakila. La solución implementa autenticación segura mediante Google OAuth, manejo de sesión con JWT, incluyendo mecanismo de revocación real, control de acceso basado en roles, manejo centralizado de excepciones y un sistema de registro de eventos de auditoría, logs en UTC, utilizando patrones de diseño Observer y principios SOLID.

## Stack Tecnológico

| Componente | Tecnología | Versión |
| :--- | :--- | :--- |
| **Backend** | Java | 17 |
| | Spring Boot | 4.1.0 |
| | Spring Security | Integrado |
| | Spring Data JPA | Integrado |
| | JWT (io.jsonwebtoken) | 0.11.5 |
| | Maven | Integrado |
| **Frontend** | Flutter SDK | 3.12.2 o superior |
| | Dart | 3 o superior |
| | Provider (Gestión de Estado) | 6.1.2 o superior |
| | HTTP (Peticiones REST) | 1.2.1 o superior |
| | JWT Decoder | 2.0.1 o superior |
| | Flutter Secure Storage | 9.2.1 o superior |
| **Base de Datos** | MySQL | 8 o superior |

## Base de Datos Seleccionada
**Sakila.** Se implementa el proceso completo de alquiler y devolución, utilizando las siguientes tablas y entidades relacionadas:

| Dominio o Agrupación | Entidad | Tabla Física |
| :--- | :--- | :--- |
| **Catálogo de Películas** | Películas | `film` |
| | Categorías | `category` |
| | Lenguajes | `language` |
| **Gestión de Stock** | Inventario de copias | `inventory` |
| **Usuarios del Negocio** | Clientes | `customer` |
| | Personal | `staff` |
| **Transacciones** | Alquileres | `rental` |
| | Pagos | `payment` |
| **Seguridad y Auditoría** | Usuarios de la App | `app_user` |
| | Tokens Revocados | `revoked_token` |
| | Trazas de Logs | `audit_log` |

## Requisitos Previos

| Requisito | Descripción |
| :--- | :--- |
| **Java Development Kit (JDK)** | Versión 17 o superior. |
| **Flutter SDK** | Instalado y configurado en el PATH del sistema. |
| **Servidor MySQL** | Versión 8.0 o superior. |
| **Google Cloud** | Cuenta activa para obtener credenciales de OAuth2. |

## Estructura General del Proyecto
```text
project_LaraAnderson/
├── backend/                  # Backend Spring Boot (API REST)
│   ├── src/main/java/com/example/demo/
│   │   ├── controllers/      # Endpoints REST expuestos
│   │   ├── services/         # Lógica de negocio transaccional
│   │   ├── repositories/     # Interfaces JPA
│   │   ├── security/         # Filtros JWT y verificación Google OAuth
│   │   ├── models/           # Entidades JPA (AppUser, Film, Rental, etc.)
│   │   └── exceptions/       # Excepciones de negocio
│   └── pom.xml
├── frontend/                 # Frontend Flutter Web
│   ├── lib/
│   │   ├── pages/            # Vistas (Admin, Cliente, Login, Detalles)
│   │   ├── services/         # Clientes API
│   │   └── providers/        # Gestión de estado (AuthProvider global)
│   └── pubspec.yaml
├── database/                 # Scripts SQL necesarios
├── postman/                  # Carpeta para almacenar colecciones Postman
├── .env.example              # Plantilla base de variables de entorno
└── README.md                 # Documentación
```

## Instrucciones de Instalación
1. Clonar este repositorio en tu máquina local.
2. Instalar las dependencias del backend usando Maven.
3. Instalar las dependencias del frontend ejecutando `flutter pub get` dentro de la carpeta `/frontend`.

## Configuración de la Base de Datos
Deben ejecutarse los scripts SQL en el siguiente orden estricto dentro de su servidor MySQL local:
1. Importar el esquema original: `database/sakila-schema.sql`
2. Importar los datos iniciales: `database/sakila-data.sql`
3. **Importar la extensión del proyecto**: `database/sakila-modity.sql`. (Este script es fundamental, ya que agrega las tablas de usuarios, logs de auditoría, tokens revocados y las banderas de disponibilidad a las tablas originales).

## Configuración de Google OAuth
1. Dirigirse a [Google Cloud Console](https://console.cloud.google.com/).
2. Crear un nuevo proyecto o usar uno existente.
3. En la sección *API & Services* > *Credentials*, crear una nueva credencial **ID de cliente de OAuth**.
4. Configurar el tipo de aplicación como "Aplicación web".
5. En los **Orígenes autorizados de JavaScript**, añadir: `http://localhost:3000`.
6. Copiar el **ID de cliente** generado y colocarlo en el archivo `.env`.

## Variables de Entorno
Crear un archivo `.env` en la raíz del proyecto basándose en el archivo `.env.example` proporcionado:

```env
# Configuración de la Base de Datos
MYSQL_ROOT_PASSWORD=su_contraseña_root
MYSQL_DATABASE=sakila
MYSQL_USER=root
MYSQL_PASSWORD=su_contraseña_root
DB_URL=jdbc:mysql://localhost:3306/sakila?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true

# Autenticación JWT y Google
GOOGLE_CLIENT_ID=TU_CLIENT_ID_DE_GOOGLE.apps.googleusercontent.com
JWT_SECRET=una_clave_secreta_jwt_lo_suficientemente_larga_y_segura
JWT_EXPIRATION=86400000

# Configuración de Correo
MAIL_USERNAME=correo@gmail.com
MAIL_PASSWORD=app_password
```
*(Nota: El backend y `docker-compose.yml` están configurados para inyectar automáticamente estas variables).*

## Comandos de Ejecución

### 1. Ejecutar el Backend (Spring Boot)
Abrir una terminal en la carpeta raíz y ejecutar:
```bash
cd backend
./mvnw spring-boot:run
```

### 2. Ejecutar el Cliente (Flutter Web)
Abrir una nueva terminal, forzando el puerto `3000` que es el configurado en Google Cloud Console:
```bash
cd frontend
flutter run -d chrome --web-port 3000
```

## Direcciones
- **Backend (API REST):** `http://localhost:8080`
- **Cliente Web:** `http://localhost:3000`

## Roles Implementados
El JWT decodificado en el frontend y validado en el backend maneja dos niveles estandarizados:
1. **ADMIN:** Acceso al dashboard administrativo completo. Puede consultar registros, modificar estado de películas/inventario y visualizar los logs de auditoría del sistema.
2. **CUSTOMER:** Orientado a clientes. Solo puede ver el catálogo público disponible, verificar disponibilidad, alquilar películas y consultar sus alquileres. Las rutas administrativas (ej. `/api/admin/**`) son denegadas (`403 Forbidden`) por el servidor si un cliente intenta consumirlas.

## Instrucciones para Probar el Flujo
1. Abrir `http://localhost:3000`.
2. Presionar el botón "Continuar con Google" para iniciar sesión (se generará la cuenta automáticamente en la base de datos).
3. **Flujo Alquiler (Cliente):**
   - Buscar y seleccionar una película en la vista de Catálogo.
   - Si la película tiene ejemplares disponibles, proceder al alquiler (checkout simulado).
   - Ver la confirmación y revisar la pestaña "Mis Alquileres" para observar que el ejemplar ahora consta como prestado y el inventario bajó.
4. **Flujo Administrador:**
   - *(Para pruebas: modificar el campo `role` del usuario a 'ADMIN' directo en la tabla `app_user` en MySQL).*
   - Volver a iniciar sesión en la web. Ahora aparecerá un Sidebar Administrativo.
   - Entrar al Panel de Auditoría para revisar todos los logs de los alquileres recientes (se registran en UTC automáticamente).
   - Acceder al Inventario de Películas para activar o desactivar la visibilidad de una película en el catálogo.
5. **Prueba de Cierre de Sesión Efectivo:**
   - Hacer clic en "Cerrar sesión".
   - El token se agregará a la tabla `revoked_token`. Si se intenta enviar una solicitud Postman con ese token antiguo interceptado, el servidor responderá `401 Unauthorized - Token Revocado`.

## Enlace de la Colección de Postman

