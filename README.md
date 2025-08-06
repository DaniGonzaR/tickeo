# Tickeo - División Automática de Cuentas

Una aplicación móvil intuitiva y visualmente atractiva para dividir automáticamente cuentas grupales a partir del escaneo OCR preciso de tickets utilizando Flutter y Firebase.

## 🚀 Características Principales

### ✅ Funcionalidades Implementadas
- **Escaneo OCR de Tickets**: Extracción automática de productos, precios y totales usando Google ML Kit
- **Selección Individual**: Cada usuario puede seleccionar qué productos consumió
- **División Inteligente**: Cálculo automático de montos individuales y división equitativa opcional
- **Gestión de Pagos**: Marcar pagos y especificar métodos (efectivo, tarjeta, transferencia, etc.)
- **Sin Registro Obligatorio**: Funciona inmediatamente sin crear cuenta
- **Compartir Fácil**: Códigos únicos y QR para unirse a cuentas
- **Almacenamiento Local**: Historial de tickets escaneados
- **Sincronización Opcional**: Respaldo en Firebase para usuarios registrados

### 🎨 Diseño y UX
- Interfaz moderna con Material Design 3
- Colores atractivos y gradientes
- Animaciones fluidas y transiciones
- Soporte para modo claro y oscuro
- Tipografía consistente con fuente Poppins

## 📱 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── models/                   # Modelos de datos
│   ├── bill.dart            # Modelo principal de cuenta
│   ├── bill_item.dart       # Items individuales de la cuenta
│   └── payment.dart         # Sistema de pagos
├── providers/               # Gestión de estado con Provider
│   ├── app_provider.dart    # Configuración de la app
│   ├── auth_provider.dart   # Autenticación
│   └── bill_provider.dart   # Lógica de cuentas
├── screens/                 # Pantallas principales
│   ├── home_screen.dart     # Pantalla principal
│   ├── bill_details_screen.dart # División y gestión de cuentas
│   └── join_bill_screen.dart    # Unirse a cuentas existentes
├── services/                # Servicios externos
│   ├── ocr_service.dart     # Reconocimiento de texto
│   └── firebase_service.dart   # Backend y almacenamiento
├── utils/                   # Utilidades y constantes
│   ├── app_colors.dart      # Esquema de colores
│   ├── app_text_styles.dart # Estilos de texto
│   └── theme.dart          # Configuración de tema
└── widgets/                 # Componentes reutilizables
    ├── custom_button.dart   # Botón personalizado
    ├── bill_history_card.dart # Tarjeta de historial
    ├── bill_item_card.dart  # Tarjeta de producto
    ├── participant_card.dart # Tarjeta de participante
    └── payment_summary_card.dart # Resumen de pagos
```

## 🛠️ Instalación y Configuración

### Prerrequisitos
- Flutter SDK (versión 3.0 o superior)
- Dart SDK
- Android Studio / VS Code
- Cuenta de Firebase

### 1. Clonar y Configurar el Proyecto
```bash
# Clonar el repositorio
git clone <repository-url>
cd bill_splitter

# Instalar dependencias
flutter pub get
```

### 2. Configuración de Firebase
```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar Firebase para el proyecto
flutterfire configure
```

### 3. Configuración de Permisos

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>Esta app necesita acceso a la cámara para escanear tickets</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Esta app necesita acceso a la galería para seleccionar imágenes de tickets</string>
```

### 4. Ejecutar la Aplicación
```bash
flutter run
```

## 🔧 Configuración Avanzada

### Firebase Security Rules (Firestore)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Bills collection
    match /bills/{billId} {
      allow read, write: if true; // Para MVP - ajustar según necesidades
    }
    
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Configuración de ML Kit
El proyecto ya incluye la configuración necesaria para Google ML Kit. No se requiere configuración adicional.

## 📖 Uso de la Aplicación

### 1. Crear una Nueva Cuenta
- **Escanear Ticket**: Usa la cámara para capturar un ticket físico
- **Seleccionar de Galería**: Elige una imagen existente
- **Crear Manualmente**: Agrega productos manualmente

### 2. Gestionar Participantes
- Agrega participantes con sus nombres
- Cada participante puede seleccionar sus productos
- División automática de productos compartidos

### 3. Dividir la Cuenta
- **División Itemizada**: Cada persona paga solo lo que consumió
- **División Equitativa**: Divide el total entre todos los participantes
- Incluye impuestos y propinas proporcionalmente

### 4. Gestionar Pagos
- Marca pagos como completados
- Especifica método de pago
- Seguimiento en tiempo real del progreso

### 5. Compartir Cuentas
- Genera códigos únicos de 8 caracteres
- Comparte códigos QR
- Los participantes pueden unirse fácilmente

## 🧪 Testing

```bash
# Ejecutar tests unitarios
flutter test

# Ejecutar tests de integración
flutter drive --target=test_driver/app.dart
```

## 📦 Build para Producción

### Android
```bash
flutter build apk --release
# o para App Bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🔮 Funcionalidades Futuras

- [ ] Escáner QR integrado
- [ ] Notificaciones push
- [ ] Exportar reportes PDF
- [ ] Integración con apps de pago
- [ ] Soporte multiidioma completo
- [ ] Análisis de gastos
- [ ] Grupos permanentes de usuarios

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 🆘 Soporte

Si encuentras algún problema o tienes preguntas:

1. Revisa la documentación
2. Busca en los issues existentes
3. Crea un nuevo issue con detalles del problema

## 🙏 Agradecimientos

- Google ML Kit por el reconocimiento de texto
- Firebase por el backend y almacenamiento
- Flutter team por el framework
- Comunidad de desarrolladores por las librerías utilizadas

---

**Desarrollado con ❤️ usando Flutter**
