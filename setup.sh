#!/bin/bash

echo "🚀 Configurando Bill Splitter App..."
echo "=================================="

# Verificar que Flutter esté instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter no está instalado. Por favor instala Flutter primero."
    exit 1
fi

echo "✅ Flutter encontrado"

# Verificar versión de Flutter
flutter --version

# Limpiar proyecto
echo "🧹 Limpiando proyecto..."
flutter clean

# Instalar dependencias
echo "📦 Instalando dependencias..."
flutter pub get

# Verificar configuración
echo "🔍 Verificando configuración..."
flutter doctor

echo ""
echo "🔥 Configuración de Firebase"
echo "============================"
echo "Para completar la configuración, necesitas:"
echo "1. Crear un proyecto en Firebase Console (https://console.firebase.google.com)"
echo "2. Instalar Firebase CLI: npm install -g firebase-tools"
echo "3. Instalar FlutterFire CLI: dart pub global activate flutterfire_cli"
echo "4. Ejecutar: flutterfire configure"
echo ""

# Verificar si Firebase CLI está instalado
if command -v firebase &> /dev/null; then
    echo "✅ Firebase CLI encontrado"
    firebase --version
else
    echo "⚠️  Firebase CLI no encontrado. Instala con: npm install -g firebase-tools"
fi

# Verificar si FlutterFire CLI está instalado
if command -v flutterfire &> /dev/null; then
    echo "✅ FlutterFire CLI encontrado"
else
    echo "⚠️  FlutterFire CLI no encontrado. Instala con: dart pub global activate flutterfire_cli"
fi

echo ""
echo "📱 Próximos pasos:"
echo "=================="
echo "1. Configura Firebase: flutterfire configure"
echo "2. Ejecuta la app: flutter run"
echo "3. Prueba el escaneo OCR con un ticket real"
echo ""
echo "🎉 ¡Configuración inicial completada!"
