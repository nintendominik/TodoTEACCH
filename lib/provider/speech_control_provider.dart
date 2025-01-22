import 'package:flutter/material.dart';

class SpeechControlProvider with ChangeNotifier {
  bool _isSpeechEnabled = true;

  bool get isSpeechEnabled => _isSpeechEnabled;

  void toggleSpeech() {
    _isSpeechEnabled = !_isSpeechEnabled;
    notifyListeners();
  }

  void setSpeechEnabled(bool isEnabled) {
    _isSpeechEnabled = isEnabled;
    notifyListeners();
  }
}
