import 'dart:ui';

import 'package:todoapp/model/task.dart';

class Plan {
  late String planName;
  late String patientName;
  late int numberOfTasks;
  late String timeFrameStart;
  late String timeFrameEnd;
  late bool isVoiceEnabled;
  late bool isWeatherEnabled;
  late List<Task> tasks;

  Plan({
    required this.planName,
    required this.patientName,
    required this.numberOfTasks,
    required this.timeFrameStart,
    required this.timeFrameEnd,
    required this.isVoiceEnabled,
    required this.isWeatherEnabled,
    required this.tasks,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    var tasksFromJson = json['tasks'] as List;
    List<Task> taskList = tasksFromJson
        .map((task) => Task(
              taskName: task['taskName'],
              taskDescription: task['taskDescription'],
              taskHelpText: task['taskHelpText'],
              taskCardColor: Color(
                  int.parse(task['taskCardColor'].substring(1, 7), radix: 16) +
                      0xFF000000),
              taskFormat: TaskFormatExtension.fromString(task['taskFormat']),
              taskPictures: (task['taskPictures'] as List)
                  .map((picture) => TaskPicture(
                        pictureName: picture['pictureName'],
                        pictureURL: picture['pictureURL'],
                      ))
                  .toList(),
            ))
        .toList();

    return Plan(
      planName: json['planName'],
      patientName: json['patientName'],
      numberOfTasks: json['numberOfTasks'],
      timeFrameStart: json['timeFrameStart'],
      timeFrameEnd: json['timeFrameEnd'],
      isVoiceEnabled: json['isVoiceEnabled'],
      isWeatherEnabled: json['isWeatherEnabled'],
      tasks: taskList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planName': planName,
      'patientName': patientName,
      'numberOfTasks': numberOfTasks,
      'timeFrameStart': timeFrameStart,
      'timeFrameEnd': timeFrameEnd,
      'isVoiceEnabled': isVoiceEnabled,
      'isWeatherEnabled': isWeatherEnabled,
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
  }
}
