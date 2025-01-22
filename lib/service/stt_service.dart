import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';

import '../provider/speech_control_provider.dart';

class STTService {
  final Function(String) onResult;
  final Function(String) onError;
  final BuildContext context;
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;

  STTService({required this.onResult, required this.onError, required this.context});

  Future<void> initialize() async {
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        print('onStatus: $status');
        if (status == 'notListening') {
          restartListening();
        }
      },
      onError: (errorNotification) {
        print('onError: $errorNotification');
        restartListening();
      },
    );

    if (available) {
      _startListening();
    } else {
      onError("Spracherkennung ist nicht verfügbar");
    }
  }

  void _startListening() {
    if (!_isListening && Provider.of<SpeechControlProvider>(context, listen: false).isSpeechEnabled) {
      _isListening = true;
      _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 20),
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
        ),
      );
    }
  }

  void restartListening() {
    stopListening();
    if (Provider.of<SpeechControlProvider>(context, listen: false).isSpeechEnabled) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _startListening();
      });
    }
  }

  void stopListening() async {
    _isListening = false;
    await _speechToText.stop();
  }

  void dispose() async {
    stopListening();
  }
}
