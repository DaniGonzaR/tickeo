# Tickeo - Smart Bill Splitting App

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Material%20Design-757575?style=for-the-badge&logo=material-design&logoColor=white" alt="Material Design">
</div>

<div align="center">
  <h3> The smartest way to split bills with friends</h3>
  <p>Scan receipts, assign items, and split costs fairly - all in one beautiful app!</p>
</div>

---

## Features

### Core Features
- **OCR Receipt Scanning**: Scan physical receipts with your camera (mobile)
- **Smart Extraction**: Automatically extract products, prices, and totals
- **Individual Selection**: Each person picks their own items
- **Fair Splitting**: Equal split or itemized based on selections
- **Payment Tracking**: Track payments with multiple methods (cash, card, transfer)
- **Bill History**: Keep all your bills organized locally
- **Easy Sharing**: Share via links and QR codes
- **Cross-Platform**: Works on Android, iOS, and Web

### User Experience
- **Material Design 3**: Beautiful, modern interface
- **Dark/Light Theme**: Automatic theme switching
- **Responsive Design**: Perfect on any screen size
- **Fast & Smooth**: Optimized performance
- **Privacy First**: Your data stays on your device

## Technology Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.x |
| **Language** | Dart |
| **State Management** | Provider Pattern |
| **OCR Engine** | Google ML Kit |
| **Backend** | Firebase (Optional) |
| **Storage** | Local + Cloud Sync |
| **UI Framework** | Material Design 3 |
| **Platforms** | Android, iOS, Web |

## Quick Start

### Prerequisites
```bash
# Required
Flutter SDK 3.0+
Dart SDK
Android Studio / VS Code

# For mobile development
Android SDK (Android)
Xcode (iOS - macOS only)
```

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/DaniGonzaR/tickeo.git
   cd tickeo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # Web (recommended for testing)
   flutter run -d chrome
   
   # Mobile (requires device/emulator)
   flutter run
   
   # Check available devices
   flutter devices
   ```

### Detailed Setup
For comprehensive setup instructions, see [**QUICK_START.md**](QUICK_START.md)

## Project Structure

```
ticket/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                # Data models
│   │   ├── bill.dart            # Bill structure
│   │   ├── bill_item.dart       # Individual items
│   │   └── payment.dart         # Payment tracking
│   ├── providers/            # State management
│   │   ├── app_provider.dart    # Global app state
│   │   ├── auth_provider.dart   # Authentication
│   │   └── bill_provider.dart   # Bill management
│   ├── screens/              # UI screens
│   │   ├── home_screen.dart     # Main dashboard
│   │   ├── bill_details_screen.dart # Bill editing
│   │   └── join_bill_screen.dart # Join shared bills
│   ├── services/             # Business logic
│   │   ├── firebase_service.dart # Cloud sync
│   │   └── ocr_service.dart     # Receipt scanning
│   ├── utils/                # Themes & utilities
│   │   ├── app_colors.dart      # Color palette
│   │   ├── app_text_styles.dart # Typography
│   │   └── theme.dart           # App theming
│   └── widgets/              # Reusable components
│       ├── bill_history_card.dart
│       ├── bill_item_card.dart
│       ├── custom_button.dart
│       ├── participant_card.dart
│       └── payment_summary_card.dart
├── Documentation/
│   ├── QUICK_START.md           # Setup guide
│   ├── FIREBASE_SETUP.md        # Firebase config
│   └── MOBILE_SETUP.md          # Mobile-specific setup
└── Configuration/
    ├── pubspec.yaml             # Dependencies (web)
    └── pubspec_firebase.yaml    # Dependencies (mobile)
```

## How to Use

### Creating a New Bill
1. **Create**: Tap "Create New Bill" on the home screen
2. **Name**: Give your bill a memorable name
3. **Scan**: Add items by scanning receipt or manually
4. **Invite**: Add participants to the bill
5. **Assign**: Let each person select their items
6. **Split**: Review the fair split and share!

### Joining a Shared Bill
1. **Receive**: Get a bill link or QR code from a friend
2. **Open**: Click the link or scan the QR code
3. **Select**: Choose your items from the bill
4. **Pay**: Mark your payment status when done

## Configuration

### Web Version (Current Default)
- Runs in any modern web browser
- Local storage for bills
- No Firebase dependency
- Perfect for testing and development

### Mobile Version with Firebase
To enable full mobile features:

```bash
# Switch to Firebase configuration
cp pubspec_firebase.yaml pubspec.yaml
cp main_firebase.dart main.dart
flutter pub get

# Follow Firebase setup guide
# See FIREBASE_SETUP.md for details
```

## Contributing

We welcome contributions! Here's how:

1. **Fork** the repository
2. **Branch**: Create your feature branch
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Code**: Make your changes
4. **Test**: Ensure everything works
5. **Commit**: Commit with clear messages
   ```bash
   git commit -m 'Add amazing feature'
   ```
6. **Push**: Push to your branch
   ```bash
   git push origin feature/amazing-feature
   ```
7. **PR**: Open a Pull Request
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
