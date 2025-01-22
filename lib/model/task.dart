import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Task {
  late String uuid;
  late String taskName;
  late String taskDescription;
  late String taskHelpText;
  late Color taskCardColor;
  late TaskFormat taskFormat;
  late List<TaskPicture> taskPictures;

  Task({
    String? uuid,
    required this.taskName,
    required this.taskDescription,
    required this.taskHelpText,
    required this.taskCardColor,
    required this.taskFormat,
    required this.taskPictures,
  }) : uuid = uuid ?? const Uuid().v4();

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskName: json['taskName'],
      taskDescription: json['taskDescription'],
      taskHelpText: json['taskHelpText'],
      taskCardColor: Color(
          int.parse(json['taskCardColor'].substring(1, 7), radix: 16) +
              0xFF000000),
      taskFormat: TaskFormatExtension.fromString(json['taskFormat']),
      taskPictures: (json['taskPictures'] as List)
          .map((picture) => TaskPicture.fromJson(picture))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskName': taskName,
      'taskDescription': taskDescription,
      'taskHelpText': taskHelpText,
      'taskCardColor': '#${taskCardColor.value.toRadixString(16).substring(2)}',
      'taskFormat': taskFormat.toShortString(),
      'taskPictures': taskPictures.map((picture) => picture.toJson()).toList(),
    };
  }
}

class TaskPicture {
  late String pictureName;
  late String pictureURL;

  Map<String, dynamic> toJson() {
    return {
      'pictureName': pictureName,
      'pictureURL': pictureURL,
    };
  }

  TaskPicture({
    required this.pictureName,
    required this.pictureURL,
  });

  factory TaskPicture.fromJson(Map<String, dynamic> json) {
    return TaskPicture(
      pictureName: json['pictureName'],
      pictureURL: json['pictureURL'],
    );
  }
}

enum TaskFormat { single, dual }

extension TaskFormatExtension on TaskFormat {
  static TaskFormat fromString(String value) {
    switch (value) {
      case 'single':
        return TaskFormat.single;
      case 'dual':
        return TaskFormat.dual;
      default:
        throw ArgumentError('Unknown TaskFormat value: $value');
    }
  }

  String toShortString() {
    return toString().split('.').last;
  }
}
