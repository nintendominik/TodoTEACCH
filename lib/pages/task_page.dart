import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:todoapp/api/weather_api.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/pages/betreuertext_popup.dart';
import 'package:weather/weather.dart';

import '../model/plan.dart';
import '../model/task.dart';
import '../provider/speech_control_provider.dart';
import '../service/stt_service.dart';

class TaskPage extends StatefulWidget {
  final String? planPath; // Optionaler Pfad

  const TaskPage({super.key, this.planPath});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  final FlutterTts _flutterTts = FlutterTts();
  Plan? _currentPlan;

  late STTService _sttService;
  String _lastWords = '';

  late String _weatherString = "";

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      _currentPageNotifier.value = _pageController.page?.toInt() ?? 0;
    });
    _loadPlans();
    _initSTTService();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    Weather weather = await WeatherApi().getWeather();
    setState(() {
      _weatherString =
          "${weather.weatherDescription}, Min: ${weather.tempMin?.celsius?.toStringAsFixed(1)}°C Max: ${weather.tempMax?.celsius?.toStringAsFixed(1)}°C";
    });
  }

  Future<void> _loadPlans() async {
    // Hole den Verzeichnispfad für das Dokumentenverzeichnis
    final directory = await getApplicationDocumentsDirectory();
    final plansDirectory = Directory("${directory.path}/Plans");

    // Hole alle Dateien im Ordner
    List<FileSystemEntity> files = plansDirectory.listSync();

    // Filtere die JSON-Dateien im Verzeichnis
    List<File> planFiles = files
        .where((file) => file.path.endsWith('.json'))
        .map((file) => File(file.path))
        .toList();

    List<Plan> plans = [];
    if (widget.planPath != null) {
      // Lade den Plan von dem übergebenen Pfad
      final file = File(widget.planPath!);
      if (await file.exists()) {
        final String response = await file.readAsString();
        final Map<String, dynamic> data = json.decode(response);
        Plan plan = Plan.fromJson(data);
        plans.add(plan);
        setState(() {
          _currentPlan = plan; // Setze den Plan direkt ohne Zeitprüfung
        });
      } else {
        print('Plan file not found: ${widget.planPath}');
      }
    } else {
      // Lade alle Plan-Dateien
      for (File planFile in planFiles) {
        final String response = await planFile.readAsString();
        print(response);
        final Map<String, dynamic> data = json.decode(response);
        Plan plan = Plan.fromJson(data);
        plans.add(plan);
      }
      DateFormat timeFormat = DateFormat.Hms();
      DateTime now = DateTime.now();
      for (Plan plan in plans) {
        DateTime startTime = timeFormat.parse(plan.timeFrameStart);
        DateTime endTime = timeFormat.parse(plan.timeFrameEnd);

        // Combine the current date with the parsed times
        DateTime startDateTime = DateTime(now.year, now.month, now.day,
            startTime.hour, startTime.minute, startTime.second);
        DateTime endDateTime = DateTime(now.year, now.month, now.day,
            endTime.hour, endTime.minute, endTime.second);

        if (now.isAfter(startDateTime) && now.isBefore(endDateTime)) {
          setState(() {
            _currentPlan = plan;
          });
          break;
        }
      }
    }
  }

  Future<void> _speak(String text, String language) async {
    await _flutterTts.setLanguage(language);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(text);
  }

  void _initSTTService() {
    requestPermissions().then((_) {
      if (mounted) {
        _sttService = STTService(
            onResult: _onSpeechResult,
            onError: _onSpeechError,
            context: context);
        _sttService.initialize();
      }
    });
  }

  void _onSpeechResult(String recognizedWords) {
    setState(() {
      _lastWords = recognizedWords;
      if (_lastWords.toLowerCase().contains('zurück')) {
        _navigateToPreviousPage();
        print('Befehl "Zurück" erkannt');
      } else if (_lastWords.toLowerCase().contains('weiter')) {
        _navigateToNextPage();
        print('Befehl "Weiter" erkannt');
      }
    });
  }

  void _onSpeechError(String error) {
    print('Spracherkennungsfehler: $error');
  }

  Future<void> requestPermissions() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    var speechStatus = await Permission.speech.status;
    if (!speechStatus.isGranted) {
      await Permission.speech.request();
    }
  }

  void _navigateToNextPage() {
    if (_currentPageNotifier.value < _currentPlan!.tasks.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _sttService.restartListening();
    }
  }

  void _navigateToPreviousPage() {
    if (_currentPageNotifier.value > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _sttService.restartListening();
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _pageController.dispose();
    _currentPageNotifier.dispose();
    _sttService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final speechControl = Provider.of<SpeechControlProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_weatherString),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _currentPlan != null && _currentPlan!.tasks.isNotEmpty
          ? Stack(
              children: [
                AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    final currentTask = _currentPlan!.tasks[_currentPageNotifier.value];
                    final nextTask = _currentPageNotifier.value + 1 < _currentPlan!.tasks.length ? _currentPlan!.tasks[_currentPageNotifier.value + 1] : currentTask;

                    double diff = 0.0;
                    if (_pageController.positions.isNotEmpty) {
                      double page = _pageController.page ?? _currentPageNotifier.value.toDouble();
                      diff = (page - _currentPageNotifier.value).abs(); // Differenz der Seitenposition
                    }
                    Color currentColor = currentTask.taskCardColor;
                    Color nextColor = nextTask.taskCardColor;
                    Color mixedColor = Color.lerp(currentColor, nextColor, diff)!;
                    return Container(
                      decoration: BoxDecoration(
                        color: mixedColor, // Übergangsfarbe
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.only(
                        left: 16,
                        top: 32,
                        right: 16,
                        bottom: 16,
                      ),
                    );
                  },
                ),
                PageView.builder(
                  controller: _pageController,
                  itemCount: _currentPlan!.tasks.length,
                  onPageChanged: (index) {
                    _currentPageNotifier.value = index;
                  },
                  itemBuilder: (context, index) {
                    final currentTask = _currentPlan!.tasks[index];
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 1000, // Feste Breite für den Bildbereich
                            height: 500, // Feste Höhe für den Bildbereich
                            child: currentTask.taskFormat == TaskFormat.dual
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children:
                                        currentTask.taskPictures.map((picture) {
                                      return SizedBox(
                                        width:
                                            500, // Feste Breite für jedes Bild im Dual-Format
                                        height: 800, // Feste Höhe
                                        child: Image.file(
                                          File(picture
                                              .pictureURL), // Bild von lokalem Pfad laden
                                          fit: BoxFit
                                              .contain, // Bild an die Größe anpassen
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : SizedBox(
                                    width:
                                        500, // Feste Breite für ein einzelnes Bild
                                    height: 500, // Feste Höhe
                                    child: Image.file(
                                      File(currentTask
                                          .taskPictures[0].pictureURL),
                                      fit: BoxFit
                                          .contain, // Bild an die Größe anpassen
                                    ),
                                  ),
                          ),
                          Text(
                            currentTask.taskDescription,
                            style: const TextStyle(fontSize: 50),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 40,
                  right: 30,
                  child: ElevatedButton(
                    child: Text(localization.caregiverText),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return BetreuerTextPopup(
                                betreuerText: _currentPlan!
                                    .tasks[_currentPageNotifier.value]
                                    .taskHelpText);
                          });
                    },
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentPageNotifier,
                    builder: (context, currentPage, child) {
                      return LinearProgressBar(
                        maxSteps: _currentPlan!.tasks.length,
                        progressType: LinearProgressBar.progressTypeDots,
                        currentStep: currentPage,
                        backgroundColor: Colors.grey,
                        progressColor: Colors.greenAccent,
                        dotsSpacing: const EdgeInsets.only(right: 10),
                        dotsActiveSize: 10,
                        dotsInactiveSize: 8,
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 24.0,
                  left: 24.0,
                  child: IconButton(
                    onPressed: () async {
                      speechControl.toggleSpeech();
                      if (speechControl.isSpeechEnabled) {
                        _sttService.initialize();
                      } else {
                        _sttService.stopListening();
                      }
                    },
                    icon: speechControl.isSpeechEnabled
                        ? const Icon(Icons.mic)
                        : const Icon(Icons.mic_off),
                    style: IconButton.styleFrom(
                      backgroundColor: speechControl.isSpeechEnabled
                          ? Theme.of(context).colorScheme.inversePrimary
                          : Colors.grey,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24.0,
                  right: 24.0,
                  child: IconButton(
                    onPressed: () async {
                      if (_currentPlan?.tasks[_currentPageNotifier.value]
                              .taskDescription !=
                          null) {
                        await _speak(
                            _currentPlan!.tasks[_currentPageNotifier.value]
                                .taskDescription,
                            'de-DE');
                      }
                    },
                    icon: const Icon(Icons.volume_up),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: Text('Im Moment gibt es nichts zu erledigen.')),
    );
  }
}
