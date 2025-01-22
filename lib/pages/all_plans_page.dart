import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todoapp/pages/create_plan_page.dart';
import 'package:todoapp/pages/task_page.dart';

class AllPlansPage extends StatefulWidget {
  const AllPlansPage({super.key});

  @override
  _AllPlansPageState createState() => _AllPlansPageState();
}

class _AllPlansPageState extends State<AllPlansPage> {
  List<FileSystemEntity> files = [];
  String filePathImage = "";
  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      // Hole den Dokumentenordner
      final directory = await getApplicationDocumentsDirectory();

      // Hole alle Dateien im Ordner
      final dir = Directory("${directory.path}/Plans");
      dir.createSync();
      ByteData byteData = await rootBundle.load('assets/images/NoImage.jpg');
      Uint8List imageData = byteData.buffer.asUint8List();
      // Hole den Speicherort, in dem die Datei gespeichert werden soll

      filePathImage = '${directory.path}/Placeholder.jpg';

      // Erstelle die Datei und speichere das Bild
      final file = File(filePathImage);
      file.create();
      await file.writeAsBytes(imageData);
      //String data = await DefaultAssetBundle.of(context)
      //    .loadString("assets/jsonPlans/testPlan.json");
      //final jsonResult = jsonDecode(data); //latest Dart
      //final file = File("${dir.path}/testPlan.json");
//
      //// JSON-Daten als String speichern
      //await file.writeAsString(json.encode(jsonResult));
      final fileList = dir.listSync(); // Synchrone Auflistung der Dateien

      setState(() {
        files = fileList.whereType<File>().toList();
      });
    } catch (e) {
      print("Fehler beim Laden der Dateien: $e");
    }
  }

  Future<void> _createNewFile() async {
    String? fileName = await _showFileNameDialog();

    if (fileName != null && fileName.isNotEmpty) {
      try {
        // Hole den Dokumentenordner
        final directory = await getApplicationDocumentsDirectory();

        // Erstelle eine neue Datei mit dem eingegebenen Namen
        final newFile = File('${directory.path}/Plans/$fileName.json');
        String data = '''{
 "planName": "Beispielplan",
 "patientName": "Max Mustermann",
 "numberOfTasks": 1,
 "timeFrameStart": "00:00:00",
 "timeFrameEnd": "23:59:59",
 "isVoiceEnabled": false,
 "isWeatherEnabled": false,
 "tasks": [
   {
     "taskName": "Beispielaufgabe",
     "taskDescription": "Bespiel Karten Text",
     "taskHelpText": "Beispiel Hilfetext",
     "taskCardColor": "#FFFFFF",
     "taskFormat": "single",
     "taskPictures": [
       {
         "pictureName": "NoImagefound",
         "pictureURL": "$filePathImage"
       }
      
     ]
   }
 ]
}''';
        await newFile.writeAsString(data);

        if (mounted) {
          // Navigiere zu einer neuen Seite und übergebe den Dateipfad
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePlanPage(filePath: newFile.path),
            ),
          );
        }

        // Aktualisiere die Liste der Dateien
        _loadFiles();

        // Zeige eine Bestätigung
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plan "$fileName" wurde erstellt!')),
        );
      } catch (e) {
        print("Fehler beim Erstellen der Datei: $e");
      }
    } else {
      // Zeige eine Nachricht, falls der Nutzer keinen Dateinamen eingegeben hat
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kein Dateiname eingegeben!')),
      );
    }
  }

  Future<String?> _showFileNameDialog() async {
    String fileName = '';
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Planname eingeben'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Planname',
            ),
            onChanged: (value) {
              fileName = value.trim(); // Entferne Leerzeichen
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Abbrechen, keine Rückgabe
              },
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(fileName); // Rückgabe des Dateinamens
              },
              child: const Text('Erstellen'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      // Aktualisiere die Liste der Dateien nach dem Löschen
      _loadFiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan wurde gelöscht!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Löschen des Plans!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pläne'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await _createNewFile();

              // Zeige eine Bestätigung
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Neuen Plan erstellt!')),
              );
            },
          ),
        ],
      ),
      body: files.isEmpty
          ? const Center(child: Text('Keine Pläne gefunden'))
          : ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                final fileName =
                    file.path.split('/').last.replaceAll('.json', '');

                return ListTile(
                  title: Text(fileName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TaskPage(planPath: file.path),
                            ),
                          );
                        },
                        child: const Text('Starten'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final bool? confirmed = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Bestätigung'),
                                content: const Text(
                                    'Möchten Sie diesen Plan wirklich löschen?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(false); // Abbrechen
                                    },
                                    child: const Text('Abbrechen'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(true); // Löschen bestätigen
                                    },
                                    child: const Text('Löschen'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmed == true) {
                            _deleteFile(
                                file as File); // Datei löschen, wenn bestätigt
                          }
                        },
                        child: const Text('Löschen'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _onFileButtonPressed(file);
                        },
                        child: const Text('Öffnen'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _onFileButtonPressed(FileSystemEntity file) {
    // Navigiere zur Detailseite der Datei und übergebe den Dateipfad
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePlanPage(filePath: file.path),
      ),
    );
  }
}
