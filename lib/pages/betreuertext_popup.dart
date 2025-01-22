import 'package:flutter/material.dart';
import 'package:todoapp/api/google_translate_api.dart';

import '../main.dart';

class BetreuerTextPopup extends StatefulWidget {
  final String betreuerText;

  const BetreuerTextPopup({
    super.key,
    required this.betreuerText,
  });

  @override
  _BetreuerTextPopupState createState() => _BetreuerTextPopupState();
}

class _BetreuerTextPopupState extends State<BetreuerTextPopup> {

  String shownBetreuerText = '';

  @override
  void initState() {
    super.initState();
    shownBetreuerText = widget.betreuerText;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setBetreuerTextWithLocale();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
            ),
            child: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // Adjust horizontal padding as needed
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  mainAxisSize: MainAxisSize.min, // Ensures the Row size is only as big as its content
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GestureDetector(
                        onTap: _translateToUkrainian,
                        child: Image.asset(
                          'assets/flags/ukrainian_flag.webp',
                          width: 90.0,
                          height: 90.0,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GestureDetector(
                        onTap: _translateToCroatian,
                        child: Image.asset(
                          'assets/flags/croatian_flag.webp',
                          width: 120.0,
                          height: 120.0,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GestureDetector(
                        onTap: _translateToGerman,
                        child: Image.asset(
                          'assets/flags/german_flag.webp',
                          width: 100.0,
                          height: 100.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              shownBetreuerText,
              style: const TextStyle(fontSize: 20.0),
            ),
          ),
        ],
      ),
    );
  }

  void _setBetreuerTextWithLocale() async {
    Locale currentLocale = Localizations.localeOf(context);

    if (currentLocale.languageCode == 'uk') {
      await _translateBetreuerText('uk');
    } else if (currentLocale.languageCode == 'hr') {
      await _translateBetreuerText('hr');
    } else {
      await _translateBetreuerText('de');
    }
  }

  Future<void> _translateToUkrainian() async {
    const String languageCode = 'uk';
    await _translateBetreuerText(languageCode);
    _changeLocale(languageCode);
    print("Translate to Ukrainian");
  }

  Future<void> _translateToCroatian() async {
    const String languageCode = 'hr';
    await _translateBetreuerText(languageCode);
    _changeLocale(languageCode);
    print("Translate to Croatian");
  }

  Future<void> _translateToGerman() async {
    const String languageCode = 'de';
    await _translateBetreuerText(languageCode);
    _changeLocale(languageCode);
    print("Translate to German");
  }

  void _changeLocale(String langaugeCode) {
    MyApp.setLocale(context, Locale(langaugeCode));
  }

  Future<void> _translateBetreuerText(String languageCode) async {
    if (widget.betreuerText.isEmpty) {
      return;
    }

    String translatedText = await GoogleTranslateAPI.translate(widget.betreuerText, languageCode);
    setState(() {
      shownBetreuerText = translatedText;
    });
  }

}
