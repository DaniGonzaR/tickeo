import 'package:flutter/material.dart';

/// Utilidades para manejar el comportamiento del teclado virtual
class KeyboardUtils {
  /// Configuración recomendada para Scaffold para evitar rebote del teclado
  static const bool scaffoldResizeToAvoidBottomInset = false;
  
  /// Configuración recomendada para SingleChildScrollView
  static const ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = 
      ScrollViewKeyboardDismissBehavior.onDrag;
  
  /// Physics recomendadas para evitar rebote
  static const ScrollPhysics scrollPhysics = ClampingScrollPhysics();
  
  /// Oculta el teclado cuando se toca fuera de un campo de texto
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
  
  /// Wrapper para GestureDetector que oculta el teclado al tocar
  static Widget dismissKeyboardOnTap({
    required BuildContext context,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: child,
    );
  }
  
  /// Calcula el padding bottom considerando el teclado
  static EdgeInsets getPaddingWithKeyboard(
    BuildContext context, {
    double left = 16.0,
    double top = 16.0,
    double right = 16.0,
    double bottom = 16.0,
  }) {
    return EdgeInsets.only(
      left: left,
      top: top,
      right: right,
      bottom: bottom + MediaQuery.of(context).viewInsets.bottom,
    );
  }
}
