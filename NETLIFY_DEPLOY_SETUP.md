# 🚀 Configuración de Deploy en Netlify

## ❌ Error Actual
El deploy falla porque las credenciales de EmailJS están en `.gitignore` y no están disponibles en Netlify.

## ✅ Solución: Variables de Entorno

### 1. Configurar Variables de Entorno en Netlify

#### **Paso 1: Ir al Dashboard de Netlify**
1. Ve a [https://app.netlify.com/](https://app.netlify.com/)
2. Selecciona tu sitio de Tickeo
3. Ve a **Site settings** → **Environment variables**

#### **Paso 2: Agregar Variables de EmailJS**
Agrega estas 4 variables con tus credenciales reales:

| Variable | Valor | Descripción |
|----------|-------|-------------|
| `EMAILJS_SERVICE_ID` | `service_8yszrio` | Tu Service ID de EmailJS |
| `EMAILJS_TEMPLATE_ID` | `template_3y6t142` | Tu Template ID de EmailJS |
| `EMAILJS_PUBLIC_KEY` | `aHizuvd5moHSyrDuP` | Tu Public Key de EmailJS |
| `EMAILJS_PRIVATE_KEY` | `aQ8RbGG0HBtnG94TzOWuv` | Tu Private Key de EmailJS |

#### **Paso 3: Guardar y Redesplegar**
1. **Guarda** las variables de entorno
2. Ve a **Deploys** → **Trigger deploy** → **Deploy site**
3. ✅ **El deploy debería funcionar ahora**

### 2. Cómo Funciona

#### **En Desarrollo Local:**
- Usa los valores por defecto hardcodeados
- Las credenciales están en el código (seguro para desarrollo)

#### **En Netlify (Producción):**
- Usa las variables de entorno de Netlify
- Las credenciales están seguras y no en el código
- Se pasan al build con `--dart-define`

### 3. Verificar Configuración

#### **En los Logs de Deploy:**
Busca estas líneas para verificar que las variables se están usando:
```
📍 Environment variables:
  EMAILJS_SERVICE_ID: service_8yszrio
  EMAILJS_TEMPLATE_ID: template_3y6t142
  EMAILJS_PUBLIC_KEY: aHizuvd5moHSyrDuP
  EMAILJS_PRIVATE_KEY: aQ8RbGG0HBtnG94TzOWuv
```

#### **Si ves "not set":**
- Las variables de entorno no están configuradas en Netlify
- Repite los pasos 1-3 arriba

### 4. Seguridad

#### **✅ Ventajas de este Método:**
- **Credenciales seguras**: No están en el código fuente
- **Fácil rotación**: Cambiar credenciales sin tocar código
- **Diferentes entornos**: Desarrollo vs producción
- **No se suben a Git**: Máxima seguridad

#### **🔒 Mejores Prácticas:**
- Nunca pongas credenciales reales en el código
- Usa variables de entorno para todos los secretos
- Rota las credenciales periódicamente
- Limita el acceso a las variables de entorno

### 5. Troubleshooting

#### **Si el deploy sigue fallando:**

1. **Verifica las variables:**
   - Ve a Netlify → Site settings → Environment variables
   - Asegúrate de que las 4 variables estén configuradas

2. **Revisa los logs:**
   - Ve a Netlify → Deploys → [último deploy] → Deploy log
   - Busca errores específicos

3. **Prueba localmente:**
   ```bash
   flutter build web --release \
     --dart-define=EMAILJS_SERVICE_ID=tu_service_id \
     --dart-define=EMAILJS_TEMPLATE_ID=tu_template_id \
     --dart-define=EMAILJS_PUBLIC_KEY=tu_public_key \
     --dart-define=EMAILJS_PRIVATE_KEY=tu_private_key
   ```

4. **Redeploy manual:**
   - Ve a Netlify → Deploys
   - Haz clic en "Trigger deploy" → "Deploy site"

### 6. Resultado Esperado

Después de configurar correctamente:
- ✅ **Deploy exitoso** en Netlify
- ✅ **Emails funcionando** en producción
- ✅ **Credenciales seguras** (no en código)
- ✅ **Verificación de email** operativa

¡Una vez configurado, todos los deploys futuros funcionarán automáticamente! 🚀
