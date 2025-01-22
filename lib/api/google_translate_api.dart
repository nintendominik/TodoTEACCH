import 'package:translator/translator.dart';

class GoogleTranslateAPI {
  static final _translator = GoogleTranslator();

  static Future<String> translate(String text, String targetLanguage) async {
    Translation translation = await _translator.translate(text, to: targetLanguage);
    return translation.text;
  }

}