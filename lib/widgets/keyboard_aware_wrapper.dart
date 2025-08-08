import 'package:flutter/material.dart';

/// Widget que envuelve contenido para manejar correctamente el teclado virtual
/// y prevenir el rebote molesto en formularios móviles
class KeyboardAwareWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool dismissKeyboardOnTap;
  final ScrollPhysics? physics;

  const KeyboardAwareWrapper({
    super.key,
    required this.child,
    this.padding,
    this.dismissKeyboardOnTap = true,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = padding ?? const EdgeInsets.all(16.0);
    
    Widget content = SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: physics ?? const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        left: defaultPadding.left,
        right: defaultPadding.right,
        top: defaultPadding.top,
        bottom: defaultPadding.bottom + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: child,
    );

    if (dismissKeyboardOnTap) {
      content = GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: content,
      );
    }

    return content;
  }
}

/// Extension para facilitar el uso del KeyboardAwareWrapper
extension WidgetKeyboardAware on Widget {
  Widget keyboardAware({
    EdgeInsets? padding,
    bool dismissKeyboardOnTap = true,
    ScrollPhysics? physics,
  }) {
    return KeyboardAwareWrapper(
      padding: padding,
      dismissKeyboardOnTap: dismissKeyboardOnTap,
      physics: physics,
      child: this,
    );
  }
}
