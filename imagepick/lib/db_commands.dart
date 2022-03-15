import 'dart:async';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
//import 'package:path/path.dart';

import 'package:flutter/widgets.dart';

class DiseaseMethods {
  static Future<void> insertDisease(Disease disease, Database database) async {
    final db = database;

    await db.insert(
      "diseaseTable",
      disease.diseaseToMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  static Future<void> updateDisease(Disease disease, Database database) async {
    final db = database;

    await db.update(
      "diseaseTable",
      disease.diseaseToMap(),
      where: "diseaseName = ?",
      whereArgs: [disease.diseaseName],
    );
  }

  static Future<void> deleteDisease(Disease disease, Database database) async {
    final db = database;

    await db.delete(
      "diseaseTable",
      where: "diseaseName = ?",
      whereArgs: [disease.diseaseName],
    );
  }

  static Future showTable(Database database) async {
    final db = database;

    final List<Map<dynamic, dynamic>> maps = await db.query("diseaseTable");

    return Logger().i(List.generate(maps.length, (i) {
      return Disease(
          diseaseName: maps[i]["diseaseName"],
          symptoms: maps[i]["symptoms"],
          todo: maps[i]["todo"],
          more: maps[i]["more"]);
    }));
  }

  static Future<int> lengthOfTable(Database database,
      {bool log = false}) async {
    Database db = database;
    final List<Map<dynamic, dynamic>> maps = await db.query("diseaseTable");

    final int lenghtOfMap = maps.length;
    if (log == true) {
      Logger().i("There are total of $lenghtOfMap entries in the database!");
    }

    return lenghtOfMap;
  }
}

class Disease {
  final String diseaseName;
  final String symptoms;
  final String todo;
  final String more;

  Disease(
      {required this.diseaseName,
      required this.symptoms,
      required this.todo,
      required this.more});

  Map<String, String> diseaseToMap() {
    return {
      "diseaseName": diseaseName,
      "symptoms": symptoms,
      "todo": todo,
      "more": more,
    };
  }

  @override
  String toString() {
    return 'Disease{diseaseName: $diseaseName, todo: $todo, more: $more}';
  }
}
