# 🔥 Guía de Configuración de Firebase

Esta guía te llevará paso a paso para configurar Firebase en tu aplicación Bill Splitter.

## 📋 Prerrequisitos

- Cuenta de Google
- Node.js instalado (para Firebase CLI)
- Flutter SDK configurado

## 🚀 Paso 1: Crear Proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Haz clic en "Crear un proyecto"
3. Nombre del proyecto: `bill-splitter-app` (o el que prefieras)
4. Acepta los términos y continúa
5. **Opcional**: Habilita Google Analytics
6. Selecciona región (recomendado: us-central1)

## 🛠️ Paso 2: Instalar Herramientas

### Firebase CLI
```bash
npm install -g firebase-tools
```

### FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### Verificar instalación
```bash
firebase --version
flutterfire --version
```

## 📱 Paso 3: Configurar Apps en Firebase

### Android App
1. En Firebase Console, haz clic en "Agregar app" → Android
2. **Package name**: `com.example.bill_splitter` (o tu preferido)
3. **App nickname**: `Bill Splitter Android`
4. **SHA-1**: Opcional por ahora
5. Descarga `google-services.json`
6. **NO lo coloques manualmente** - FlutterFire lo hará

### iOS App
1. Haz clic en "Agregar app" → iOS
2. **Bundle ID**: `com.example.billSplitter`
3. **App nickname**: `Bill Splitter iOS`
4. Descarga `GoogleService-Info.plist`
5. **NO lo coloques manualmente** - FlutterFire lo hará

## ⚡ Paso 4: Configurar con FlutterFire

```bash
# Desde la raíz del proyecto
flutterfire configure
```

**Selecciona:**
- Tu proyecto de Firebase
- Plataformas: Android, iOS
- Confirma la configuración

Esto creará automáticamente:
- `firebase_options.dart` (actualizado)
- Colocará archivos de configuración en lugares correctos

## 🔐 Paso 5: Configurar Authentication

1. En Firebase Console → Authentication
2. Haz clic en "Comenzar"
3. Pestaña "Sign-in method"
4. Habilita:
   - **Anonymous** (para usuarios sin cuenta)
   - **Email/Password** (para cuentas permanentes)

## 🗄️ Paso 6: Configurar Firestore

1. En Firebase Console → Firestore Database
2. Haz clic en "Crear base de datos"
3. **Modo**: Empezar en modo de prueba
4. **Ubicación**: us-central1 (o tu región preferida)

### Reglas de Seguridad (Temporal)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir lectura/escritura para desarrollo
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**⚠️ IMPORTANTE**: Estas reglas son para desarrollo. Cambiar antes de producción.

## 📊 Paso 7: Configurar Storage (Opcional)

1. En Firebase Console → Storage
2. Haz clic en "Comenzar"
3. Acepta reglas por defecto
4. Selecciona ubicación

## 🧪 Paso 8: Probar la Configuración

```bash
# Instalar dependencias
flutter pub get

# Ejecutar la app
flutter run
```

### Verificar en Logs
Busca en la consola:
```
✅ Firebase initialized successfully
✅ Firestore connected
```

## 🔧 Paso 9: Configuración Avanzada

### Reglas de Firestore para Producción
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Bills collection
    match /bills/{billId} {
      allow read: if true; // Cualquiera puede leer con código
      allow write: if request.auth != null; // Solo usuarios autenticados pueden escribir
    }
    
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Índices Recomendados
En Firestore → Índices, crear:
- `bills` colección: `shareCode` (ASC), `createdAt` (DESC)
- `bills` colección: `createdBy` (ASC), `createdAt` (DESC)

## 🚨 Solución de Problemas

### Error: "Default FirebaseApp is not initialized"
```bash
# Ejecutar nuevamente
flutterfire configure
```

### Error de permisos Android
Verificar que `android/app/src/main/AndroidManifest.xml` tenga:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### Error de permisos iOS
Verificar que `ios/Runner/Info.plist` tenga las descripciones de uso.

### Error de dependencias
```bash
flutter clean
flutter pub get
```

## 📱 Paso 10: Probar Funcionalidades

1. **Crear cuenta**: Debe funcionar sin registro
2. **Escanear ticket**: OCR debe procesar imagen
3. **Compartir código**: Debe generar código único
4. **Unirse a cuenta**: Debe cargar cuenta compartida

## 🎉 ¡Listo!

Tu aplicación Bill Splitter ahora está completamente configurada con Firebase. 

### Próximos pasos recomendados:
1. Probar todas las funcionalidades
2. Ajustar reglas de seguridad
3. Configurar índices para mejor rendimiento
4. Preparar para producción

### Enlaces útiles:
- [Firebase Console](https://console.firebase.google.com)
- [FlutterFire Documentation](https://firebase.flutter.dev)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
