# Cognito JWT API

API REST con Ruby on Rails implementando autenticación JWT mediante AWS Cognito.

## 🚀 Características

- **Ruby on Rails 8.0.2** en modo API
- **Autenticación JWT** con AWS Cognito
- **PostgreSQL** como base de datos
- **RSpec** para pruebas unitarias e integración
- **Factory Bot** y **Faker** para datos de prueba
- Endpoints RESTful protegidos
- CORS habilitado para aplicaciones frontend

## 📋 Requisitos Previos

- Ruby 3.4.2
- Rails 8.0.2
- PostgreSQL
- Cuenta de AWS con acceso a Cognito
- Bundler

## 🛠️ Instalación

### 1. Clonar el repositorio

```bash
git clone <repository-url>
cd cognito-jwt-api
```

### 2. Instalar dependencias

```bash
bundle install
```

### 3. Configurar variables de entorno

Copiar el archivo de ejemplo y configurar las variables:

```bash
cp .env.example .env
```

Editar `.env` con tus configuraciones:

```env
# Database Configuration
DATABASE_USERNAME=tu_usuario_postgres
DATABASE_PASSWORD=tu_password_postgres
DATABASE_HOST=localhost
DATABASE_PORT=5432

# AWS Cognito Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=tu_access_key
AWS_SECRET_ACCESS_KEY=tu_secret_key
COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
COGNITO_CLIENT_ID=tu_client_id
COGNITO_CLIENT_SECRET=tu_client_secret
COGNITO_DOMAIN=tu-app.auth.us-east-1.amazoncognito.com
```

### 4. Configurar la base de datos

```bash
rails db:create
rails db:migrate
rails db:seed # Opcional: para cargar datos de ejemplo
```

### 5. Ejecutar el servidor

```bash
rails server
```

La API estará disponible en `http://localhost:3000`

## 🔐 Configuración de AWS Cognito

### 1. Crear un User Pool en AWS Cognito

1. Accede a la consola de AWS Cognito
2. Crea un nuevo User Pool con las siguientes configuraciones:
   - **Sign-in options**: Username y Email
   - **Password policy**: Según tus requerimientos
   - **Multi-factor authentication**: Opcional
   - **User account recovery**: Email

### 2. Configurar App Client

1. En tu User Pool, ve a "App clients"
2. Crea un nuevo App client con:
   - **App client name**: tu-app-name
   - **Generate client secret**: Sí (necesario para el flujo de autenticación)
   - **Auth Flows**: 
     - USER_PASSWORD_AUTH
     - ALLOW_REFRESH_TOKEN_AUTH

### 3. Obtener las credenciales

Después de crear el User Pool y App Client, obtendrás:
- User Pool ID
- Client ID
- Client Secret

Estos valores deben agregarse al archivo `.env`

## 📚 API Endpoints

### Autenticación

#### Registro de usuario
```http
POST /api/v1/auth/signup
Content-Type: application/json

{
  "auth": {
    "username": "johndoe",
    "password": "Password123!",
    "email": "john@example.com",
    "name": "John Doe"
  }
}
```

#### Iniciar sesión
```http
POST /api/v1/auth/signin
Content-Type: application/json

{
  "auth": {
    "username": "johndoe",
    "password": "Password123!"
  }
}

Response:
{
  "access_token": "eyJraWQiOiJ...",
  "id_token": "eyJraWQiOiJ...",
  "refresh_token": "eyJjdHkiOiJ...",
  "expires_in": 3600
}
```

### Posts (Endpoints Protegidos)

#### Listar posts
```http
GET /api/v1/posts
Authorization: Bearer <access_token>
```

#### Crear un post
```http
POST /api/v1/posts
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "post": {
    "title": "Mi nuevo post",
    "content": "Contenido del post",
    "published": true
  }
}
```

## 🧪 Pruebas

### Ejecutar todas las pruebas
```bash
bundle exec rspec
```

### Ejecutar pruebas específicas
```bash
# Pruebas de modelos
bundle exec rspec spec/models

# Pruebas de requests
bundle exec rspec spec/requests
```

## 🏗️ Estructura del Proyecto

```
cognito-jwt-api/
├── app/
│   ├── controllers/
│   │   ├── api/v1/
│   │   │   ├── auth_controller.rb
│   │   │   ├── posts_controller.rb
│   │   │   └── users_controller.rb
│   │   └── concerns/
│   │       └── jwt_authenticatable.rb
│   ├── models/
│   │   └── post.rb
│   └── services/
│       └── cognito_auth_service.rb
├── config/
│   ├── database.yml
│   └── routes.rb
├── spec/
│   ├── factories/
│   ├── models/
│   └── requests/
└── Gemfile
```

## 📝 Licencia

Este proyecto está bajo la licencia MIT.
# cognito-jwt-api
