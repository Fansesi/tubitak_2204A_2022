import 'dart:async';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
//import 'package:path/path.dart';

import 'package:flutter/widgets.dart';

/*void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase("diseaseDatabase2.db", onCreate: (db, version) {
    return db.execute(
        "CREATE TABLE diseaseTable(diseaseName TEXT, symptoms TEXT, todo TEXT, more TEXT)");
  }, version: 1);

  Future<void> insertDisease(Disease disease) async {
    final db = await database;

    await db.insert(
      "diseaseTable",
      disease.diseaseToMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDisease(Disease disease) async {
    final db = await database;

    await db.update(
      "diseaseTable",
      disease.diseaseToMap(),
      where: "diseaseName = ?",
      whereArgs: [disease.diseaseName],
    );
  }

  Future<void> deleteDisease(Disease disease) async {
    final db = await database;

    await db.delete(
      "diseaseTable",
      where: "diseaseName = ?",
      whereArgs: [disease.diseaseName],
    );
  }

  Future showTable() async {
    //<List<Disease>>
    final db = await database;

    final List<Map<dynamic, dynamic>> maps = await db.query("diseaseTable");

    Logger().i(maps.length);

    return List.generate(maps.length, (i) {
      return Disease(
          diseaseName: maps[i]["diseaseName"],
          symptoms: maps[i]["symptoms"],
          todo: maps[i]["todo"],
          more: maps[i]["more"]);
    });
  }

  var healthy = Disease(
    diseaseName: "healthy",
    symptoms: "symptomsHEA",
    todo: "todoHEA",
    more: "moreHEA",
  );
  var cocci = Disease(
    diseaseName: "cocci",
    symptoms: "symptomsCOC",
    todo: "todoCOC",
    more: "moreCOC",
  );
  var salmon = Disease(
    diseaseName: "salmon",
    symptoms: "symptomsSAL",
    todo: "todoSAL",
    more: "moreSAL",
  );
  var ncd = Disease(
    diseaseName: "ncd",
    symptoms: "symptomsNCD",
    todo: "todoNCD",
    more: "moreNCD",
  );

  var denem2 = Disease(
      diseaseName: "denem",
      symptoms: "symptomsDEN",
      todo: "todoDEN",
      more: "moreDEN");

  Logger().i("Starting to insert!");
  await insertDisease(healthy);
  await insertDisease(cocci);
  await insertDisease(salmon);
  await insertDisease(ncd);
  Logger().i("Insertion done!");

  Logger().i(await showTable());
}
*/
/*void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database =
      await openDatabase("diseaseDatabase2.db", onCreate: (db, version) {
    return db.execute(
        "CREATE TABLE diseaseTable(diseaseName TEXT, symptoms TEXT, todo TEXT, more TEXT)");
  }, version: 1);

  DiseaseMethods.showTable(database);

  DiseaseMethods.deleteDisease(healthy, database);
  DiseaseMethods.deleteDisease(cocci, database);
  DiseaseMethods.deleteDisease(salmon, database);
  DiseaseMethods.deleteDisease(ncd, database);

}
*/

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
