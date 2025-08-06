# 🔍 TICKEO - VERIFICACIÓN DE FUNCIONALIDADES NATIVAS

## 🎯 OBJETIVO
Verificar que todas las funcionalidades nativas (Share, QR, Enlaces) funcionen correctamente en web, móvil y escritorio.

## 📱 FUNCIONALIDADES A VERIFICAR

### **1. 📤 COMPARTIR NATIVO (share_plus)**

**Ubicación:** BillDetailsScreen > Botón Share > "Compartir como Texto"

**Código relevante:**
```dart
await Share.share(
  summary,
  subject: 'Cuenta de Tickeo - ${billNameController.text}',
);
```

**Pruebas:**
- [ ] **Web:** Debe usar fallback (clipboard)
- [ ] **Android:** Debe abrir selector nativo de apps
- [ ] **iOS:** Debe abrir sheet nativo de compartir
- [ ] **Desktop:** Debe funcionar con apps instaladas

**Resultado esperado:**
- Texto formateado con emojis y estructura clara
- Información completa de productos y participantes
- Totales calculados correctamente

### **2. 📱 CÓDIGOS QR (qr_flutter)**

**Ubicación:** BillDetailsScreen > Botón Share > "Mostrar Código QR"

**Código relevante:**
```dart
QrImageView(
  data: shareUrl,
  version: QrVersions.auto,
  size: 200.0,
  backgroundColor: Colors.white,
)
```

**Pruebas:**
- [ ] **Generación:** QR se genera correctamente
- [ ] **Contenido:** URL válida dentro del QR
- [ ] **Escaneo:** QR es escaneable por apps externas
- [ ] **Responsive:** Tamaño adecuado en diferentes pantallas

**Datos del QR:**
```
https://tickeo.app/join?bill=BILL_ID&name=BILL_NAME
```

### **3. 🔗 ABRIR ENLACES (url_launcher)**

**Ubicación:** BillDetailsScreen > Botón Share > "Generar Enlace"

**Código relevante:**
```dart
await launchUrl(
  Uri.parse(shareUrl),
  mode: LaunchMode.externalApplication,
);
```

**Pruebas:**
- [ ] **Web:** Abre en nueva pestaña
- [ ] **Móvil:** Abre en navegador predeterminado
- [ ] **Desktop:** Abre en navegador del sistema
- [ ] **Fallback:** Manejo de errores si no puede abrir

### **4. 📋 PORTAPAPELES (Clipboard)**

**Ubicación:** BillDetailsScreen > Botón Share > "Copiar Resumen"

**Código relevante:**
```dart
Clipboard.setData(ClipboardData(text: summary));
```

**Pruebas:**
- [ ] **Copia correcta:** Texto se copia al portapapeles
- [ ] **Formato:** Mantiene estructura y emojis
- [ ] **Feedback:** SnackBar confirma la acción
- [ ] **Multiplataforma:** Funciona en todas las plataformas

## 🧪 ESCENARIOS DE PRUEBA

### **Escenario 1: Cuenta Simple**
```
Cuenta: "Cena en el restaurante"
Productos: Pizza (€15.00), Bebidas (€8.00)
Participantes: Ana, Carlos
Total: €23.00
```

### **Escenario 2: Cuenta Compleja**
```
Cuenta: "Compras del supermercado"
Productos: 5 items con diferentes precios
Participantes: 4 personas
Asignaciones: Productos específicos por persona
Total: €67.50
```

### **Escenario 3: Cuenta con Caracteres Especiales**
```
Cuenta: "Café & Té ☕"
Productos: Café (€3.50), Té (€2.80)
Participantes: José, María
Total: €6.30
```

## 📊 CHECKLIST DE VERIFICACIÓN

### **✅ Preparación**
- [ ] Crear cuenta de prueba con datos variados
- [ ] Tener dispositivos/navegadores listos
- [ ] Preparar apps para escanear QR (opcional)

### **✅ Share Nativo**
- [ ] Probar en Chrome (web)
- [ ] Probar en dispositivo Android
- [ ] Probar en dispositivo iOS (si disponible)
- [ ] Verificar formato del texto compartido
- [ ] Confirmar que incluye toda la información

### **✅ Códigos QR**
- [ ] Generar QR desde la app
- [ ] Verificar que el QR es visible y claro
- [ ] Escanear con app externa (Google Lens, etc.)
- [ ] Confirmar que el enlace es válido
- [ ] Probar en diferentes tamaños de pantalla

### **✅ Enlaces**
- [ ] Generar enlace desde la app
- [ ] Verificar que se abre correctamente
- [ ] Probar en diferentes navegadores
- [ ] Confirmar estructura de URL
- [ ] Verificar parámetros de la URL

### **✅ Portapapeles**
- [ ] Copiar resumen al portapapeles
- [ ] Pegar en otra app para verificar
- [ ] Confirmar formato y contenido
- [ ] Verificar feedback visual (SnackBar)

## 🐛 PROBLEMAS COMUNES Y SOLUCIONES

### **Share no funciona en web:**
```dart
// Fallback implementado
try {
  await Share.share(summary);
} catch (e) {
  await Clipboard.setData(ClipboardData(text: summary));
  // Mostrar mensaje de fallback
}
```

### **QR no se genera:**
```dart
// Verificar dependencia
qr_flutter: ^4.1.0
```

### **URL no se abre:**
```dart
// Verificar configuración de url_launcher
if (await canLaunchUrl(uri)) {
  await launchUrl(uri);
} else {
  // Mostrar error
}
```

## 📱 CONFIGURACIÓN REQUERIDA

### **Android (android/app/src/main/AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### **iOS (ios/Runner/Info.plist):**
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>https</string>
  <string>http</string>
</array>
```

## 🎯 CRITERIOS DE ÉXITO

### **✅ Funcionalidad Completa:**
- Share funciona en todas las plataformas
- QR se genera y es escaneable
- Enlaces se abren correctamente
- Portapapeles funciona sin errores

### **✅ Experiencia de Usuario:**
- Feedback visual claro
- Manejo elegante de errores
- Tiempos de respuesta aceptables
- Interfaz intuitiva

### **✅ Robustez:**
- Funciona con diferentes tipos de datos
- Maneja caracteres especiales
- Recuperación de errores
- Compatibilidad multiplataforma

---

**🚀 ¡Lista para verificar todas las funcionalidades nativas de Tickeo!**
