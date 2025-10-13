# Guía de Seguridad - Tickeo

## 🔐 Configuración de Variables de Entorno

### Configuración Inicial

1. **Copia el archivo de ejemplo:**
   ```bash
   cp .env.example .env
   ```

2. **Configura tus claves API en `.env`:**
   ```env
   # EmailJS Configuration
   EMAILJS_SERVICE_ID=tu_service_id_real
   EMAILJS_TEMPLATE_ID=tu_template_id_real
   EMAILJS_PUBLIC_KEY=tu_public_key_real
   EMAILJS_PRIVATE_KEY=tu_private_key_real
   ```

### Para Desarrollo

```bash
# Ejecutar con variables de entorno
flutter run --dart-define=EMAILJS_SERVICE_ID=tu_service_id
```

### Para Producción Web

```bash
# Build con variables de entorno
flutter build web --dart-define=EMAILJS_SERVICE_ID=tu_service_id --dart-define=EMAILJS_TEMPLATE_ID=tu_template_id --dart-define=EMAILJS_PUBLIC_KEY=tu_public_key --dart-define=EMAILJS_PRIVATE_KEY=tu_private_key
```

## 🚫 Archivos Protegidos

Los siguientes archivos **NUNCA** deben subirse a Git:

- `.env` - Variables de entorno
- `lib/config/*_config.dart` - Configuraciones sensibles
- `**/*_secrets.dart` - Archivos de secretos
- `**/*_keys.dart` - Archivos de claves

## ✅ Buenas Prácticas

### ✅ Hacer:
- Usar variables de entorno para todas las claves API
- Verificar que `.env` está en `.gitignore`
- Usar `AppConfig.isEmailJsConfigured` antes de usar EmailJS
- Mantener `.env.example` actualizado

### ❌ NO Hacer:
- Hardcodear claves API en el código
- Subir archivos `.env` a Git
- Usar valores por defecto en `String.fromEnvironment`
- Compartir claves API en mensajes o documentación

## 🔍 Verificación de Seguridad

Ejecuta estos comandos para verificar que no hay claves expuestas:

```bash
# Buscar posibles claves hardcodeadas
grep -r "service_" lib/ --exclude-dir=.git
grep -r "template_" lib/ --exclude-dir=.git
grep -r "key.*=" lib/ --exclude-dir=.git

# Verificar que .env no está trackeado
git status --ignored
```

## 🆘 Si Expusiste Claves Accidentalmente

1. **Revoca inmediatamente** las claves en EmailJS/Firebase
2. **Genera nuevas claves**
3. **Actualiza tu `.env`**
4. **Limpia el historial de Git** si es necesario:
   ```bash
   git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch lib/services/email_service.dart' --prune-empty --tag-name-filter cat -- --all
   ```

## 📞 Contacto

Si tienes dudas sobre seguridad, revisa la documentación o contacta al equipo de desarrollo.
