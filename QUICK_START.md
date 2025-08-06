# 🚀 Guía de Inicio Rápido - Tickeo

¡Pon en marcha tu aplicación Tickeo en menos de 10 minutos!

## ⚡ Inicio Inmediato (2 minutos)

### 1. Ejecutar Script de Configuración
```bash
# En Windows (Git Bash/WSL)
bash setup.sh

# En macOS/Linux
chmod +x setup.sh
./setup.sh
```

### 2. Probar la App (Sin Firebase)
```bash
flutter run
```

**¡Ya puedes usar la app localmente!** 
- Crea cuentas manuales
- Agrega participantes
- Divide cuentas
- Todo funciona sin conexión

## 🔥 Configuración Completa con Firebase (8 minutos)

### Paso 1: Crear Proyecto Firebase (3 min)
1. Ve a [Firebase Console](https://console.firebase.google.com)
2. "Crear un proyecto" → Nombre: `tickeo-app`
3. Habilita Google Analytics (opcional)
4. ¡Listo!

### Paso 2: Instalar Herramientas (2 min)
```bash
# Firebase CLI
npm install -g firebase-tools

# FlutterFire CLI
dart pub global activate flutterfire_cli
```

### Paso 3: Configurar Apps (2 min)
```bash
# Configuración automática
flutterfire configure
```
- Selecciona tu proyecto
- Elige Android + iOS
- Confirma

### Paso 4: Habilitar Servicios (1 min)
En Firebase Console:
1. **Authentication** → "Comenzar" → Habilitar "Anonymous" y "Email/Password"
2. **Firestore** → "Crear base de datos" → "Modo de prueba"

## 🧪 Verificar Todo Funciona

```bash
# Ejecutar verificaciones
bash test_app.sh

# Si todo está ✅, ejecutar la app
flutter run
```

## 📱 Probar Funcionalidades

### 1. Crear Primera Cuenta
- Toca "Crear Manualmente"
- Nombre: "Prueba Restaurante"
- Agrega algunos productos manualmente

### 2. Agregar Participantes
- Ve a la pestaña "Participantes"
- Agrega 2-3 personas de prueba

### 3. Seleccionar Productos
- En "Productos", cada persona selecciona lo que consumió
- Ve cómo se calcula automáticamente

### 4. Probar División
- Toca "Dividir Equitativamente" para comparar
- Ve el "Resumen" para ver totales

### 5. Compartir Cuenta
- Toca el ícono compartir en la barra superior
- Copia el código generado
- Prueba "Unirse a Cuenta" con ese código

## 🔍 Probar OCR (Opcional)

### Con Ticket Real:
1. Toca "Escanear Ticket"
2. Apunta a un ticket físico
3. Asegúrate de que esté bien iluminado
4. ¡Ve cómo extrae automáticamente los productos!

### Con Imagen de Galería:
1. Toma foto de un ticket con tu teléfono
2. En la app, toca "Seleccionar de Galería"
3. Elige la foto del ticket

## 🚨 Solución Rápida de Problemas

### Error: "Firebase not initialized"
```bash
flutterfire configure
flutter clean
flutter pub get
flutter run
```

### Error: "Camera permission denied"
- Android: Verifica `AndroidManifest.xml`
- iOS: Verifica `Info.plist`
- Reinstala la app

### OCR no funciona bien
- Asegúrate de buena iluminación
- Ticket debe estar plano y legible
- Prueba con diferentes ángulos

### Build falla
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

## 🎯 Casos de Uso Típicos

### Caso 1: Cena en Restaurante
1. Una persona escanea el ticket
2. Comparte el código con el grupo
3. Cada uno se une y selecciona sus productos
4. Marcan pagos cuando paguen su parte

### Caso 2: Compras Grupales
1. Crear cuenta manual "Compras Supermercado"
2. Agregar productos uno por uno
3. Asignar productos a quién los llevará
4. Dividir costos

### Caso 3: Viaje Grupal
1. Crear múltiples cuentas (hotel, comidas, transporte)
2. Ir agregando gastos durante el viaje
3. Al final, revisar resúmenes
4. Saldar cuentas

## 📊 Funcionalidades Avanzadas

### Propinas Inteligentes
- Agrega propina y se distribuye proporcionalmente
- Cada persona paga propina según lo que consumió

### Historial Local
- Todas las cuentas se guardan automáticamente
- Accede desde la pantalla principal

### Sincronización en la Nube
- Crea cuenta opcional para respaldo
- Accede a tus cuentas desde cualquier dispositivo

## 🔄 Flujo Completo de Ejemplo

```
1. 📸 Escanear ticket → 2. 👥 Agregar amigos → 3. ✅ Seleccionar productos
                ↓
6. 💰 Saldar cuentas ← 5. 📱 Marcar pagos ← 4. 🧮 Ver totales individuales
```

## 🆘 ¿Necesitas Ayuda?

### Documentación Completa
- `README.md` - Información general
- `FIREBASE_SETUP.md` - Configuración detallada de Firebase

### Verificar Estado
```bash
bash test_app.sh  # Diagnóstico completo
flutter doctor     # Estado de Flutter
```

### Logs de Debug
```bash
flutter run --verbose  # Logs detallados
```

---

## 🎉 ¡Listo para Usar!

Tu aplicación Tickeo está configurada y lista. Algunas ideas para probar:

- **Escanea tickets reales** de restaurantes, supermercados
- **Invita amigos** a probar la función de compartir
- **Experimenta** con diferentes tipos de división
- **Personaliza** colores y configuraciones

**¡Disfruta dividiendo cuentas sin complicaciones!** 🍕💰👥
