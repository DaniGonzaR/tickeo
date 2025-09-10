// Web implementation that calls window.runTesseract via JS interop
import 'dart:async';
import 'dart:js_util' as js_util;

Future<String> runTesseractOnWeb(String base64Url, String lang) async {
  final promise = js_util.callMethod(js_util.globalThis, 'runTesseract', [base64Url, lang]);
  final result = await js_util.promiseToFuture(promise);
  if (result is String) return result;
  return result?.toString() ?? '';
}
