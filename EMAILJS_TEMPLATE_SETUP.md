# 🔧 Configuración del Template de EmailJS

## ❌ Error Actual: "The recipients address is empty"

Este error indica que el template de EmailJS no está configurado correctamente. Aquí está la solución:

## ✅ Configuración Correcta del Template

### 1. Ve a tu dashboard de EmailJS
- Entra a [https://dashboard.emailjs.com/](https://dashboard.emailjs.com/)
- Ve a la sección "Email Templates"
- Edita tu template `template_3y6t142`

### 2. Configuración del Template

#### **To Email (IMPORTANTE):**
```
{{to_email}}
```
**⚠️ CRÍTICO: Asegúrate de que el campo "To Email" contenga exactamente `{{to_email}}`**

#### **Subject:**
```
Verifica tu cuenta en Tickeo
```

#### **Content (HTML):**
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Verificación de Email - Tickeo</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            background-color: #f5f5f5; 
            margin: 0; 
            padding: 20px; 
        }
        .container { 
            max-width: 600px; 
            margin: 0 auto; 
            background-color: white; 
            border-radius: 8px; 
            overflow: hidden; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
        }
        .header { 
            background-color: #6366f1; 
            color: white; 
            padding: 30px 20px; 
            text-align: center; 
        }
        .content { 
            padding: 30px 20px; 
        }
        .code-box { 
            background-color: #f8fafc; 
            border: 2px dashed #6366f1; 
            border-radius: 8px; 
            padding: 20px; 
            text-align: center; 
            margin: 20px 0; 
        }
        .code { 
            font-size: 32px; 
            font-weight: bold; 
            color: #6366f1; 
            letter-spacing: 4px; 
        }
        .footer { 
            background-color: #f8fafc; 
            padding: 20px; 
            text-align: center; 
            color: #64748b; 
            font-size: 14px; 
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎫 Tickeo</h1>
            <p>Verificación de Email</p>
        </div>
        
        <div class="content">
            <h2>¡Hola {{to_name}}!</h2>
            
            <p>Gracias por registrarte en Tickeo. Para completar tu registro, necesitamos verificar tu dirección de email.</p>
            
            <div class="code-box">
                <p style="margin: 0 0 10px 0; color: #64748b;">Tu código de verificación es:</p>
                <div class="code">{{verification_code}}</div>
            </div>
            
            <p>Ingresa este código en la aplicación para verificar tu cuenta.</p>
            
            <p><strong>Importante:</strong></p>
            <ul>
                <li>Este código expira en 10 minutos</li>
                <li>No compartas este código con nadie</li>
                <li>Si no solicitaste este código, ignora este email</li>
            </ul>
            
            <p>¡Gracias por usar Tickeo para dividir tus cuentas!</p>
        </div>
        
        <div class="footer">
            <p>Este email fue enviado por {{app_name}}</p>
            <p>Si tienes problemas, contacta nuestro soporte</p>
        </div>
    </div>
</body>
</html>
```

### 3. Variables del Template

Asegúrate de que estas variables estén configuradas:

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `{{to_email}}` | Email del destinatario | rephix8@gmail.com |
| `{{to_name}}` | Nombre del usuario | Daniel |
| `{{verification_code}}` | Código de 6 dígitos | 123456 |
| `{{app_name}}` | Nombre de la app | Tickeo |
| `{{from_name}}` | Nombre del remitente | Tickeo |

### 4. Configuración del Servicio

En tu servicio de EmailJS, asegúrate de:

1. **Email Service configurado** (Gmail, Outlook, etc.)
2. **Dominio verificado** (si usas dominio personalizado)
3. **Límites no excedidos** (200 emails/mes en plan gratuito)

### 5. Verificar Configuración

Después de hacer los cambios:

1. **Guarda el template**
2. **Ejecuta la app**: `flutter run -d chrome`
3. **Crea una cuenta nueva**
4. **Revisa la consola** para ver si hay errores
5. **Revisa tu email** (incluyendo spam)

### 6. Troubleshooting

#### Si sigue fallando:

**Revisa la consola del navegador:**
- Abre DevTools (F12)
- Ve a la pestaña Console
- Busca errores de EmailJS

**Errores comunes:**
- `recipients address is empty` → Campo "To Email" mal configurado
- `template not found` → Template ID incorrecto
- `service not found` → Service ID incorrecto
- `unauthorized` → Public/Private key incorrectos

#### Logs útiles:
```javascript
// En la consola del navegador, puedes probar:
console.log('Service ID:', 'service_8yszrio');
console.log('Template ID:', 'template_3y6t142');
```

### 7. Test Manual

Puedes probar el envío manualmente desde la consola del navegador:

```javascript
emailjs.send('service_8yszrio', 'template_3y6t142', {
    to_email: 'tu-email@gmail.com',
    to_name: 'Test User',
    verification_code: '123456',
    app_name: 'Tickeo',
    from_name: 'Tickeo'
}, 'aHizuvd5moHSyrDuP');
```

## 🎯 Resultado Esperado

Después de la configuración correcta:
- ✅ No más error "recipients address is empty"
- ✅ Email llega a la bandeja de entrada
- ✅ Código de verificación funciona
- ✅ Template se ve profesional

¡Una vez configurado correctamente, los emails llegarán sin problemas! 🚀
