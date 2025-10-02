# 📧 Configuración de Email para Producción

Para que tu aplicación Tickeo envíe emails reales de verificación, necesitas configurar un servicio de email. Te explico las opciones y cómo configurarlas:

## 🚀 Opción 1: EmailJS (Recomendado para empezar)

### ✅ Ventajas:
- **Gratis**: 200 emails/mes
- **Sin backend**: Funciona directamente desde Flutter Web
- **Fácil configuración**: Solo necesitas credenciales
- **Rápido setup**: 10-15 minutos

### 📋 Pasos para configurar EmailJS:

#### 1. Crear cuenta en EmailJS
- Ve a [https://www.emailjs.com/](https://www.emailjs.com/)
- Crea una cuenta gratuita
- Confirma tu email

#### 2. Configurar servicio de email
- En el dashboard, ve a "Email Services"
- Haz clic en "Add New Service"
- Selecciona tu proveedor (Gmail, Outlook, Yahoo, etc.)
- Sigue las instrucciones para conectar tu email
- **Guarda el Service ID** que aparece

#### 3. Crear template de email
- Ve a "Email Templates"
- Haz clic en "Create New Template"
- Usa este template:

```
Subject: Verifica tu cuenta en Tickeo

Body:
¡Hola {{to_name}}!

Gracias por registrarte en Tickeo. Para completar tu registro, necesitamos verificar tu dirección de email.

Tu código de verificación es: {{verification_code}}

Importante:
- Este código expira en 10 minutos
- No compartas este código con nadie
- Si no solicitaste este código, ignora este email

¡Gracias por usar Tickeo para dividir tus cuentas!

Saludos,
El equipo de Tickeo
```

- **Variables requeridas**:
  - `{{to_name}}` - Nombre del usuario
  - `{{to_email}}` - Email del usuario
  - `{{verification_code}}` - Código de 6 dígitos
  - `{{app_name}}` - Nombre de la app
- **Guarda el Template ID**

#### 4. Obtener credenciales
- Ve a "Account" → "General"
- Copia tu **Public Key**
- Ve a "Account" → "API Keys"
- Crea una **Private Key** y cópiala

#### 5. Configurar en la app
Edita el archivo `lib/config/email_config.dart`:

```dart
class EmailConfig {
  // Reemplaza con tus valores reales
  static const String emailJsServiceId = 'service_xxxxxxx';
  static const String emailJsTemplateId = 'template_xxxxxxx';
  static const String emailJsPublicKey = 'xxxxxxxxxxxxxxx';
  static const String emailJsPrivateKey = 'xxxxxxxxxxxxxxx';
  
  // Resto de configuración...
}
```

## 🏢 Opción 2: SendGrid (Para apps profesionales)

### ✅ Ventajas:
- **Muy confiable**: 99.9% de entrega
- **Escalable**: Millones de emails
- **Analytics**: Estadísticas detalladas
- **Gratis**: 100 emails/día

### ⚠️ Desventajas:
- **Requiere backend**: No funciona directamente desde Flutter Web
- **Más complejo**: Necesitas servidor o Cloud Functions

### 📋 Pasos para SendGrid:

#### 1. Crear cuenta
- Ve a [https://sendgrid.com/](https://sendgrid.com/)
- Crea cuenta gratuita
- Verifica tu email

#### 2. Verificar dominio/email
- Ve a "Settings" → "Sender Authentication"
- Verifica tu dominio o email individual
- **Importante**: Sin esto, los emails van a spam

#### 3. Crear API Key
- Ve a "Settings" → "API Keys"
- Crea una nueva API Key con permisos de "Mail Send"
- **Guarda la API Key** (solo se muestra una vez)

#### 4. Configurar en la app
```dart
class EmailConfig {
  static const String sendGridApiKey = 'SG.xxxxxxxxxxxxxxx';
  static const String sendGridFromEmail = 'noreply@tudominio.com';
  static const String sendGridFromName = 'Tickeo';
}
```

#### 5. Cambiar método de envío
En `lib/providers/auth_provider.dart`, cambia:
```dart
// Cambiar de EmailJS a SendGrid
final success = await EmailService.sendVerificationEmailSendGrid(
  _user!.email!,
  _user!.displayName!,
);
```

## 🔥 Opción 3: Firebase Auth (Más completo)

### ✅ Ventajas:
- **Todo incluido**: Maneja autenticación completa
- **Emails automáticos**: Verificación, reset password, etc.
- **Muy escalable**: Para millones de usuarios
- **Integración total**: Con toda la suite de Firebase

### 📋 Configuración rápida:
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea proyecto
3. Habilita Authentication
4. Configura Email/Password provider
5. Personaliza templates de email

## 🛠️ Instalación de dependencias

Ejecuta en tu terminal:
```bash
flutter pub get
```

## 🧪 Probar en desarrollo

1. Configura EmailJS (es lo más fácil)
2. Ejecuta la app: `flutter run -d chrome`
3. Crea una cuenta nueva
4. Revisa tu email para el código
5. Ingresa el código en la app

## 🚀 Desplegar a producción

### Para EmailJS:
1. Configura las credenciales reales
2. Compila: `flutter build web`
3. Despliega los archivos de `build/web/`

### Para SendGrid:
1. Necesitas un backend (Node.js, Python, etc.)
2. El backend llama a SendGrid API
3. Flutter llama a tu backend

## 🔒 Seguridad

### ⚠️ IMPORTANTE:
- **Nunca** pongas credenciales reales en el código fuente público
- Usa variables de entorno en producción
- Las credenciales en `email_config.dart` son solo para desarrollo

### Para producción:
```dart
// Usar variables de entorno
static const String emailJsServiceId = String.fromEnvironment('EMAILJS_SERVICE_ID');
```

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs de la consola del navegador
2. Verifica que las credenciales sean correctas
3. Asegúrate de que el servicio de email esté activo
4. Revisa la carpeta de spam

## 🎯 Recomendación

**Para empezar**: Usa EmailJS - es lo más fácil y rápido
**Para producción seria**: Considera Firebase Auth o SendGrid con backend

¡Con cualquiera de estas opciones tendrás emails reales funcionando en minutos! 🚀
