import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';

import '../model/plan.dart';
import '../model/task.dart';

class CreatePlanPage extends StatefulWidget {
  final String filePath;

  const CreatePlanPage({super.key, required this.filePath});

  @override
  _CreatePlanPageState createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends State<CreatePlanPage> {
  Plan? planData;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _timeFrameStartController;
  late TextEditingController _timeFrameEndController;
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    loadJsonData();
    _timeFrameStartController = TextEditingController();
    _timeFrameEndController = TextEditingController();
  }

  @override
  void dispose() {
    _timeFrameStartController.dispose();
    _timeFrameEndController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadJsonData() async {
    try {
      final file = File(widget.filePath);
      final contents = await file.readAsString();

      // JSON parsen
      final Map<String, dynamic> jsonResult = json.decode(contents);
      Plan loadedPlan = Plan.fromJson(jsonResult);

      setState(() {
        planData = loadedPlan;
        _timeFrameStartController.text = planData!.timeFrameStart;
        _timeFrameEndController.text = planData!.timeFrameEnd;
      });
    } catch (e) {
      print('Fehler beim Laden der JSON-Datei: $e');
    }
  }

  Future<void> saveJsonData() async {
    if (planData != null) {
      try {
        final file = File(widget.filePath);
        await file.writeAsString(json.encode(planData!.toJson()));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Änderungen gespeichert!')),
        );
        print(planData!.toJson());
      } catch (e) {
        print('Fehler beim Speichern der JSON-Datei: $e');
      }
    }
  }

  Future<void> _pickTime(BuildContext context, TextEditingController controller,
      String timeType) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          DateTime.parse("1970-01-01 ${controller.text}")),
    );

    if (pickedTime != null) {
      setState(() {
        String formattedTime =
            '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}:00';

        // Setzt den Controller-Wert auf den ausgewählten Wert
        controller.text = formattedTime;

        // Speichern Sie die Zeit im Plan-Modell
        if (timeType == 'start') {
          planData!.timeFrameStart = formattedTime;
        } else if (timeType == 'end') {
          planData!.timeFrameEnd = formattedTime;
        }
      });
    }
  }

  Future<void> _pickImage(Task task, int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        final picture = TaskPicture(
          pictureName: pickedFile.path.split('/').last,
          pictureURL: pickedFile.path,
        );

        if (task.taskPictures.length > index) {
          task.taskPictures[index] = picture;
        } else {
          task.taskPictures.add(picture);
        }
      });
      saveJsonData(); // Speichere Änderungen direkt nach der Bildauswahl
    }
  }

  void _addTask() {
    setState(() {
      planData?.tasks.add(Task(
        taskName: '',
        taskDescription: '',
        taskHelpText: '',
        taskCardColor: Colors.white,
        taskFormat: TaskFormat.single,
        taskPictures: [],
      ));
      _updateTaskCount();

      // Nach ganz unten scrollen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  void _removeTask(int index) {
    setState(() {
      planData?.tasks.removeAt(index);
      _updateTaskCount(); // Aktualisiere die Anzahl der Tasks
    });
  }

  void _updateTaskCount() {
    setState(() {
      planData?.numberOfTasks = planData?.tasks.length ?? 0;
    });
  }

  void _pickColor(Task task) {
    // Konvertiere den Hex-String in ein Color-Objekt
    Color initialColor = task.taskCardColor;

    showDialog(
      context: context,
      builder: (context) {
        Color selectedColor = initialColor;

        return AlertDialog(
          title: const Text('Farbe auswählen'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initialColor,
              onColorChanged: (color) {
                selectedColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                setState(() {
                  // Speichere die ausgewählte Farbe als Hex-String
                  task.taskCardColor = selectedColor;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan bearbeiten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                saveJsonData();
              }
            },
          ),
        ],
      ),
      body: planData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: _scrollController,
                  children: [
                    TextFormField(
                      initialValue: planData!.planName,
                      decoration: const InputDecoration(labelText: 'Planname'),
                      onSaved: (value) {
                        planData!.planName = value ?? '';
                      },
                    ),
                    TextFormField(
                      initialValue: planData!.patientName,
                      decoration:
                          const InputDecoration(labelText: 'Name Patient'),
                      onSaved: (value) {
                        planData!.patientName = value ?? '';
                      },
                    ),
                    TextFormField(
                      controller: _timeFrameStartController,
                      decoration: const InputDecoration(
                        labelText: 'von',
                        hintText: 'HH:mm:ss', // Optional: hint text
                      ),
                      readOnly: true,
                      onTap: () => _pickTime(
                          context, _timeFrameStartController, 'start'),
                    ),
                    TextFormField(
                      controller: _timeFrameEndController,
                      decoration: const InputDecoration(
                        labelText: 'bis',
                        hintText: 'HH:mm:ss', // Optional: hint text
                      ),
                      readOnly: true,
                      onTap: () =>
                          _pickTime(context, _timeFrameEndController, 'end'),
                    ),
                    SwitchListTile(
                      title: const Text('Sprachausgabe der Kartentexte'),
                      value: planData!.isVoiceEnabled,
                      onChanged: (value) {
                        setState(() {
                          planData!.isVoiceEnabled = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Wetter abhängig'),
                      value: planData!.isWeatherEnabled,
                      onChanged: (value) {
                        setState(() {
                          planData!.isWeatherEnabled = value;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Anzahl der Aufgaben: ${planData!.numberOfTasks}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Aufgaben:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: planData!.tasks.length,
                      itemBuilder: (context, index) {
                        final task = planData!.tasks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //TextFormField(
                                //initialValue: task.taskName,
                                //decoration: const InputDecoration(
                                //  labelText: 'Aufgabe'),
                                //onSaved: (value) {
                                //task.taskName = value ?? '';
                                //},
                                //),
                                TextFormField(
                                  initialValue: task.taskDescription,
                                  decoration: const InputDecoration(
                                      labelText: 'Kartentext'),
                                  onSaved: (value) {
                                    task.taskDescription = value ?? '';
                                  },
                                ),
                                TextFormField(
                                  initialValue: task.taskHelpText,
                                  decoration: const InputDecoration(
                                      labelText: 'Betreuertext'),
                                  onSaved: (value) {
                                    task.taskHelpText = value ?? '';
                                  },
                                ),
                                DropdownButtonFormField<TaskFormat>(
                                  value: task.taskFormat,
                                  decoration: const InputDecoration(
                                      labelText: 'Format'),
                                  items: const [
                                    DropdownMenuItem(
                                      value: TaskFormat.single,
                                      child: Text('1 Bild'),
                                    ),
                                    DropdownMenuItem(
                                      value: TaskFormat.dual,
                                      child: Text('2 Bilder'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      task.taskFormat =
                                          value ?? TaskFormat.single;

                                      // Wenn das Format auf 'single' geändert wird, entfernen wir das zweite Bild.
                                      if (task.taskFormat ==
                                              TaskFormat.single &&
                                          task.taskPictures.length > 1) {
                                        task.taskPictures.removeAt(
                                            1); // Entferne das zweite Bild
                                      }
                                    });
                                  },
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Gewählte Farbe: ▮',
                                      style:
                                          TextStyle(color: task.taskCardColor),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _pickColor(task),
                                      child: const Text('Farbe wählen'),
                                    ),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (task.taskFormat ==
                                        TaskFormat.single) ...[
                                      ElevatedButton(
                                        onPressed: () => _pickImage(task, 0),
                                        child: const Text('Bild wählen'),
                                      ),
                                      if (task.taskPictures.isNotEmpty)
                                        Text(
                                            '1 Bild: ${task.taskPictures[0].pictureName}'),
                                    ],
                                    if (task.taskFormat == TaskFormat.dual) ...[
                                      ElevatedButton(
                                        onPressed: () => _pickImage(task, 0),
                                        child: const Text('Bild 1 wählen'),
                                      ),
                                      if (task.taskPictures.isNotEmpty)
                                        Text(
                                            'Bild 1: ${task.taskPictures[0].pictureName}'),
                                      ElevatedButton(
                                        onPressed: () => _pickImage(task, 1),
                                        child: const Text('Bild 2 wählen'),
                                      ),
                                      if (task.taskPictures.length > 1)
                                        Text(
                                            'Bild 2: ${task.taskPictures[1].pictureName}'),
                                    ],
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _removeTask(index),
                                      child: const Text('Entfernen'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add),
        label: const Text('Aufgabe hinzufügen'),
        tooltip: 'Aufgabe hinzufügen',
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Zentriert am unteren Rand
    );
  }
}
