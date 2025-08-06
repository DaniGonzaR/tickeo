#!/bin/bash

echo "🧪 Ejecutando Pruebas de Tickeo"
echo "====================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar resultados
show_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# 1. Verificar Flutter
echo -e "${BLUE}📱 Verificando Flutter...${NC}"
flutter doctor --version > /dev/null 2>&1
show_result $? "Flutter instalado"

# 2. Verificar dependencias
echo -e "${BLUE}📦 Verificando dependencias...${NC}"
flutter pub get > /dev/null 2>&1
show_result $? "Dependencias instaladas"

# 3. Análisis estático del código
echo -e "${BLUE}🔍 Análisis estático del código...${NC}"
flutter analyze > /dev/null 2>&1
show_result $? "Análisis estático pasado"

# 4. Verificar estructura de archivos
echo -e "${BLUE}📁 Verificando estructura de archivos...${NC}"

required_files=(
    "lib/main.dart"
    "lib/models/bill.dart"
    "lib/models/bill_item.dart"
    "lib/models/payment.dart"
    "lib/services/ocr_service.dart"
    "lib/services/firebase_service.dart"
    "lib/providers/bill_provider.dart"
    "lib/providers/auth_provider.dart"
    "lib/providers/app_provider.dart"
    "lib/screens/home_screen.dart"
    "lib/screens/bill_details_screen.dart"
    "lib/screens/join_bill_screen.dart"
    "lib/utils/app_colors.dart"
    "lib/utils/app_text_styles.dart"
    "lib/utils/theme.dart"
    "pubspec.yaml"
)

missing_files=0
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}  ✅ $file${NC}"
    else
        echo -e "${RED}  ❌ $file (faltante)${NC}"
        ((missing_files++))
    fi
done

if [ $missing_files -eq 0 ]; then
    echo -e "${GREEN}✅ Todos los archivos requeridos están presentes${NC}"
else
    echo -e "${RED}❌ Faltan $missing_files archivos${NC}"
fi

# 5. Verificar configuración de Firebase
echo -e "${BLUE}🔥 Verificando configuración de Firebase...${NC}"
if [ -f "lib/firebase_options.dart" ]; then
    echo -e "${GREEN}  ✅ firebase_options.dart encontrado${NC}"
else
    echo -e "${YELLOW}  ⚠️  firebase_options.dart no encontrado - ejecuta 'flutterfire configure'${NC}"
fi

# 6. Verificar permisos Android
echo -e "${BLUE}🤖 Verificando permisos Android...${NC}"
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    if grep -q "android.permission.CAMERA" android/app/src/main/AndroidManifest.xml; then
        echo -e "${GREEN}  ✅ Permisos de cámara configurados${NC}"
    else
        echo -e "${RED}  ❌ Permisos de cámara faltantes${NC}"
    fi
    
    if grep -q "android.permission.INTERNET" android/app/src/main/AndroidManifest.xml; then
        echo -e "${GREEN}  ✅ Permisos de internet configurados${NC}"
    else
        echo -e "${RED}  ❌ Permisos de internet faltantes${NC}"
    fi
else
    echo -e "${RED}  ❌ AndroidManifest.xml no encontrado${NC}"
fi

# 7. Verificar configuración iOS
echo -e "${BLUE}🍎 Verificando configuración iOS...${NC}"
if [ -f "ios/Runner/Info.plist" ]; then
    if grep -q "NSCameraUsageDescription" ios/Runner/Info.plist; then
        echo -e "${GREEN}  ✅ Descripción de uso de cámara configurada${NC}"
    else
        echo -e "${RED}  ❌ Descripción de uso de cámara faltante${NC}"
    fi
    
    if grep -q "NSPhotoLibraryUsageDescription" ios/Runner/Info.plist; then
        echo -e "${GREEN}  ✅ Descripción de uso de galería configurada${NC}"
    else
        echo -e "${RED}  ❌ Descripción de uso de galería faltante${NC}"
    fi
else
    echo -e "${RED}  ❌ Info.plist no encontrado${NC}"
fi

# 8. Ejecutar tests unitarios
echo -e "${BLUE}🧪 Ejecutando tests unitarios...${NC}"
if [ -d "test" ] && [ "$(ls -A test)" ]; then
    flutter test > /dev/null 2>&1
    show_result $? "Tests unitarios"
else
    echo -e "${YELLOW}  ⚠️  No se encontraron tests unitarios${NC}"
fi

# 9. Verificar build para Android
echo -e "${BLUE}🔨 Verificando build Android...${NC}"
flutter build apk --debug > /dev/null 2>&1
show_result $? "Build Android debug"

# 10. Resumen final
echo ""
echo -e "${BLUE}📊 Resumen de la Verificación${NC}"
echo "================================"

# Verificar Firebase CLI
if command -v firebase &> /dev/null; then
    echo -e "${GREEN}✅ Firebase CLI instalado${NC}"
else
    echo -e "${YELLOW}⚠️  Firebase CLI no instalado${NC}"
    echo -e "${YELLOW}   Instala con: npm install -g firebase-tools${NC}"
fi

# Verificar FlutterFire CLI
if command -v flutterfire &> /dev/null; then
    echo -e "${GREEN}✅ FlutterFire CLI instalado${NC}"
else
    echo -e "${YELLOW}⚠️  FlutterFire CLI no instalado${NC}"
    echo -e "${YELLOW}   Instala con: dart pub global activate flutterfire_cli${NC}"
fi

echo ""
echo -e "${BLUE}🚀 Próximos pasos recomendados:${NC}"
echo "1. Si faltan herramientas de Firebase, instálalas"
echo "2. Ejecuta 'flutterfire configure' para configurar Firebase"
echo "3. Ejecuta 'flutter run' para probar la aplicación"
echo "4. Prueba el escaneo OCR con un ticket real"
echo ""
echo -e "${GREEN}🎉 Verificación completada!${NC}"
