import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imagepick/classifier.dart';
import 'package:imagepick/classifier_get.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:hexcolor/hexcolor.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disease Identifier',
      theme: ThemeData(
          primaryColor: HexColor("#0336FF"), 
          //colorScheme: ColorScheme(primary: HexColor("#0336FF") ),
          canvasColor: HexColor("#FFDE03"), 
          colorScheme: ColorScheme(
              primary: Colors.indigo.shade600,
              primaryVariant: Colors.indigo.shade200,
              onPrimary: Colors.white,
              secondary: Colors.cyan.shade300,
              secondaryVariant: Colors.cyanAccent.shade100,
              onSecondary: Colors.black,
              error: Colors.red.shade500,
              onError: Colors.white,
              surface: Colors.tealAccent.shade400,
              onSurface: Colors.white,
              background: Colors.indigo.shade900,
              onBackground: Colors.white,
              brightness: Brightness.light),
          fontFamily: "Oswald",
          textTheme: TextTheme(
              headline5: const TextStyle(
                fontSize: 24.0,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              bodyText1: const TextStyle(fontSize: 18.0, color: Colors.black),
              bodyText2: const TextStyle(fontSize: 18.0, color: Colors.white),
              headline6: TextStyle(
                  fontSize: 18.0,
                  color: Theme.of(context).colorScheme.onPrimary))),
      routes: {
        "SelectionPage": (context) => _SelectionPage(),
        "ViaPhoto": (context) => const ViaPhoto(),
        "ViaKeywords": (context) => const ViaKeywords(),
        "RadioPage1": (context) => const RadioPage1(),
        "InfoPage2": (context) => const _InfoPage2(),
      },
      initialRoute: "SelectionPage",
    );
  }
}

class MyDatabaseConnection {
  static Future<Database> myDB() async {
    // Construct a file path to copy database to
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path,
        "asset_database.db"); // understand why we are usnig a diffenert name here

    // Only copy if the database doesn't exist
    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
      // Load database from asset and copy
      Logger().i("Creating new copy from asset...");
      ByteData data = await rootBundle.load(join('assets', 'diseaseDBv3.db'));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Save copied asset to documents
      await File(path).writeAsBytes(bytes);
    } else {
      Logger().i("Opening existing database...");
    }
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String databasePath = join(appDocDir.path, 'asset_database.db');
    final db = await openDatabase(databasePath);
    return db;
  }

  Future<List> getDiseaseInfo(String diseaseName) async {
    /// Function to return desired map. It's used in InfoPage1()

    Database db = await myDB();
    Future<List<Map<String, dynamic>>> maps = db.query("diseaseTable",
        where: "diseaseName=?", whereArgs: [diseaseName]);

    return maps;
    //And the paramater will be getDiseaseInfo(category!.label)
    //This way there will be no messageToShow variable.
  }

  Future<List> getDiseaseInfo2({
    bool? coughing,
    bool? sneezing,
    bool? shakingHead,
    bool? rales,
    bool? gasping,
    bool? eyeDischarge,
    bool? nasalDischarge,
    bool? swelling,
    bool? discoloration,
    bool? retardedGrowth,
  }) async {
    // Function to return desired map. It is used in InfoPage2()

    boolToInt(bool? value) {
      switch (value) {
        case true:
          return "1";
        case false:
          return "0";
        case null:
          return null;
        default:
          return null;
      }
    }

    var coughingSTR = boolToInt(coughing);
    var sneezingSTR = boolToInt(sneezing);
    var shakingHeadSTR = boolToInt(shakingHead);
    var ralesSTR = boolToInt(rales);
    var gaspingSTR = boolToInt(gasping);
    var eyeDischargeSTR = boolToInt(eyeDischarge);
    var nasalDischargeSTR = boolToInt(nasalDischarge);
    var swellingSTR = boolToInt(swelling);
    var discolorationSTR = boolToInt(discoloration);
    var retardedGrowthSTR = boolToInt(retardedGrowth);

    Database db = await myDB();

    String sqlCommand1 = """coughing=? AND sneezing=? 
    AND shaking_head=? AND rales=? 
    AND gasping=? AND eye_discharge=? 
    AND nasal_discharge=? AND swelling=? 
    AND discoloration=? AND retarded_growth=?""";

    String sqlCommand2 =
        "coughing=? AND sneezing=? AND shaking_head=? AND rales=? AND gasping=? AND eye_discharge=? AND nasal_discharge=? AND swelling=? AND discoloration=? AND retarded_growth=?";

    List<Map<String, dynamic>> maps =
        await db.query("table_1", where: sqlCommand1, whereArgs: [
      coughingSTR,
      sneezingSTR,
      shakingHeadSTR,
      ralesSTR,
      gaspingSTR,
      eyeDischargeSTR,
      nasalDischargeSTR,
      swellingSTR,
      discolorationSTR,
      retardedGrowthSTR,
    ]);
    return maps;
  }
}

class _SelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Ana Sayfa",
            style: Theme.of(context).textTheme.headline5,
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Column(children: [
          Container(
            margin: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
            padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                border: Border.all(
                    width: 4.5, color: Theme.of(context).colorScheme.primary)),
            child: Text(
              """Fotoğraf yardımıyla hastalığın teşhisinin yapılmasını istiyorsanız "Fotoğraf ile Teşhis" butonuna, sorulara
cevap vererek tavuklarınzda bulunabilecek olası hastalıklar hakkında bilgi almak istiyorsanız 
"Sorular ile Teşhis" butonuna basınız. """,
              style: Theme.of(context).textTheme.bodyText1,
              textAlign: TextAlign.justify,
            ),
          ),
          Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(bottom: 20.0, top: 150),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    primary: Theme.of(context).colorScheme.primary,
                    fixedSize: const Size(180, 45),
                    //padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  ),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ViaPhoto())),
                  child: Text(
                    "Fotoğraf ile Teşhis",
                    style: Theme.of(context).textTheme.headline6,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    primary: Theme.of(context).colorScheme.primary,
                    //padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
                    fixedSize: const Size(180, 45)),
                onPressed: () => Navigator.pushNamed(
                  context,
                  "RadioPage1",
                ),
                child: Text(
                  "Sorular ile Teşhis",
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
            ],
          )),
        ]
    ));
  }
}

class ViaPhoto extends StatefulWidget {
  const ViaPhoto({Key? key, this.title = "ViaPhoto"}) : super(key: key);

  final String title;

  @override
  State<ViaPhoto> createState() => _ViaPhoto();
}

class _ViaPhoto extends State<ViaPhoto> {
  // Required Variables
  List? outputOfCNN;

  File? _image;
  Image? _imageWidget;
  img.Image? fox;

  bool _nextButisDisabled = true;

  late Classifier _classifier;

  var logger = Logger(filter: null, printer: PrettyPrinter(), output: null);

  Category? category;
  static late String predictionLabel;
  bool isCategoryNull = true;

  @override
  void initState() {
    super.initState();
    _classifier = ClassifierGet();
  }

  Future pickImageFromCamera() async {
    logger.i("[INFO] Camera button has been pressed.");
    var takenImage = await ImagePicker().pickImage(source: ImageSource.camera);
    logger.i("[INFO] Image has been picked.");

    setState(() {
      if (takenImage != null) {
        _image = File(takenImage.path);
        _imageWidget = Image.file(_image!);
      } else {
        logger.i("There isn't a photo to work on it!");
        return;
      }

      if (_image != null) {
        _nextButisDisabled = false;
      } else {
        _nextButisDisabled = true;
      }

      _predict();
      logger.i("[INFO] Prediction has been made.");
    });
  }

  Future pickImageFromGallery() async {
    logger.i("[INFO] Gallery button has been pressed.");
    final chosenImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    logger.i("[INFO] Image has been picked.");

    setState(() {
      if (chosenImage != null) {
        _image = File(chosenImage.path);
        _imageWidget = Image.file(_image!);
      } else {
        logger.i("There isn't a photo to work on it!");
        return;
      }

      if (_image != null) {
        _nextButisDisabled = false;
      } else {
        _nextButisDisabled = true;
      }

      _predict();
      logger.i("[INFO] Prediction1 func has finished");
    });
  }

  void _predict() async {
    logger.i("[INFO] Prediction Operation has been started.");
    img.Image imageInput = img.decodeImage(_image!.readAsBytesSync())!;
    var pred = _classifier.predict(imageInput);

    setState(() {
      category = pred;
      predictionLabel = category!.label;
      isCategoryNull = true;
    });
    logger.i("[INFO] Category variable is now determined.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          "Fotoğraf İle Teşhis",
          style: Theme.of(context).textTheme.headline5,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <
            Widget>[
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(15.0)),
              color: Theme.of(context).colorScheme.secondary,
              border: Border.all(
                width: 4.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            child: _image == null
                ? Container(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(
                      "Lütfen bir fotoğraf seçiniz. Soldaki butona basarak galeriden seçebilir, sağdaki butona basarak kameranızdan fotoğraf çekebilirsiniz.",
                      style: Theme.of(context).textTheme.bodyText1,
                      textAlign: TextAlign.justify,
                    ),
                  )
                : Container(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height / 2),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    child: _imageWidget,
                  ),
            margin: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 25.0),
          ),

/////////////////// BUTTONS: GALLERY OR CAMERA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.primary,
                heroTag: null,
                onPressed: () {
                  try {
                    pickImageFromGallery();
                  } catch (e) {
                    Navigator.pushNamed(context, "ViaPhoto");
                  }
                },
                tooltip: "Pick Image from Gallery",
                child: const Icon(Icons.photo),
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              FloatingActionButton(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  heroTag: null,
                  onPressed: () {
                    try {
                      pickImageFromCamera();
                    } catch (e) {
                      Navigator.pushNamed(context, "ViaPhoto");
                    }
                  },
                  tooltip: "Take Image via Camera",
                  child: const Icon(Icons.camera),
                  foregroundColor: Theme.of(context).colorScheme.onPrimary),
            ], 
          ),

////////////////// NEXT BUTTON
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                  margin: const EdgeInsets.fromLTRB(10.0, 15.0, 10.0, 5.0),
                  child: Visibility(
                      visible: _nextButisDisabled != true ? true : false,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                              primary: Theme.of(context).colorScheme.primary,
                              //padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
                              fixedSize: const Size(330, 45)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                "Hastalığa dair bilgilenmek için tıklayınız",
                                style: Theme.of(context).textTheme.bodyText2,
                              ),
                              Icon(Icons.arrow_forward_rounded,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary),
                            ],
                          ),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const InfoPage())))))
            ],
          ),
          ////////////////// TEXTBOX FOR INFO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Container(
                  margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(15.0)),
                      border: Border.all(
                          width: 4.5,
                          color: Theme.of(context).colorScheme.primary)),
                  child: category == null
                      ? Text(
                          "Sonucu göstermek için girdi bekleniyor...",
                          style: Theme.of(context).textTheme.bodyText1,
                        )
                      : Text(
                          "Tavuğunuz ${category!.label == "healthy" ? "sağlıklıdır." : """sağlıklı değildir."""}",
                          style: Theme.of(context).textTheme.bodyText1,
                          textAlign: TextAlign.justify,
                        ))
            ],
          ),
        ]),
      ),
    );
  }
}

class MyFuture extends StatelessWidget {
  MyFuture({Key? key, required this.toShow}) : super(key: key);

  final MyDatabaseConnection _myDatabaseConnection = MyDatabaseConnection();
  final String toShow;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _myDatabaseConnection.getDiseaseInfo(_ViaPhoto.predictionLabel),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          List<Widget> children;
          if (snapshot.hasData) {
            children = <Widget>[
              Text(
                "${snapshot.data[0][toShow]}",
                style: Theme.of(context).textTheme.bodyText1,
                textAlign: TextAlign.justify,
              )
            ];
          } else if (snapshot.hasError) {
            throw ErrorDescription(
                "An error has occured while displaying data");
          } else {
            children = <Widget>[
              Text("Yükleniyor...",
                  style: Theme.of(context).textTheme.bodyText1)
            ];
          }
          return Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ));
        });
  }
}

class MyTable extends StatelessWidget {
  const MyTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: const BorderRadius.all(Radius.circular(11.0)),
          border: Border.all(
            width: 6.0,
            color: Theme.of(context).colorScheme.secondary,
          )),
      padding: const EdgeInsets.all(10.0),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder.all(
          width: 4.0,
          color: Theme.of(context).colorScheme.primary,
        ),
        children: [
          TableRow(children: [
            Container(
              child: Text("Hastalığın Adı: ",
                  style: Theme.of(context).textTheme.bodyText1),
              margin: const EdgeInsets.all(10.0),
            ),
            Container(
              child: MyFuture(toShow: "diseaseNameToShow"),
              margin: const EdgeInsets.all(10.0),
            ),
          ]),
          TableRow(children: [
            Container(
              child: Text("Semptomlar: ",
                  style: Theme.of(context).textTheme.bodyText1),
              margin: const EdgeInsets.all(10.0),
            ),
            Container(
              child: MyFuture(toShow: "symptoms"),
              margin: const EdgeInsets.all(10.0),
            ),
          ]),
          TableRow(children: [
            Container(
              child: Text(
                "Yapılması Gerekenler: ",
                style: Theme.of(context).textTheme.bodyText1,
              ),
              margin: const EdgeInsets.all(10.0),
            ),
            Container(
              child: MyFuture(toShow: "todo"),
              margin: const EdgeInsets.all(10.0),
            ),
          ]),
          TableRow(children: [
            Container(
              child: Text("Daha Fazla Bilgi: ",
                  style: Theme.of(context).textTheme.bodyText1),
              margin: const EdgeInsets.all(10.0),
            ),
            Container(
              child: MyFuture(toShow: "more"),
              margin: const EdgeInsets.all(10.0),
            ),
          ]),
        ],
      ),
    );
  }
}

class InfoPage extends StatelessWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Bilgilendirme Sayfası",
            style: Theme.of(context).textTheme.headline5,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SingleChildScrollView(
            clipBehavior: Clip.antiAlias,
            child: Container(
                color: Theme.of(context).colorScheme.background,
                padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10.0)),
                      border: Border.all(
                        width: 6.0,
                        color: Theme.of(context).colorScheme.primary,
                      )),
                  child: const MyTable(),
                ))));
  }
}

class ViaKeywords extends StatefulWidget {
  const ViaKeywords({Key? key, this.title = "ViaPhoto"}) : super(key: key);

  final String title;

  @override
  State<ViaKeywords> createState() => _ViaKeywords();
}

class _ViaKeywords extends State<ViaKeywords> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("ViaKeywords")),
        body: const Center(
            child: SizedBox(
          child: RadioPage1(),
        )));
  }
}

class RadioPage1 extends StatefulWidget {
  const RadioPage1({Key? key, this.title = "RadioPage1"}) : super(key: key);

  final String title;

  @override
  State<RadioPage1> createState() => _RadioPage1();
}

class _RadioPage1 extends State<RadioPage1> {
  bool? coughing = false;
  bool? sneezing = false;
  bool? shakingHead = false;
  bool? rales = false;
  bool? gasping = false;
  bool? eyeDischarge = false;
  bool? nasalDischarge = false;
  bool? swelling = false;
  bool? discoloration = false;
  bool? retardedGrowth = false;

  final MyDatabaseConnection _myDatabaseConnection2 = MyDatabaseConnection();

  static List? messageToShow;
  static int? lengthOfMessageToShow;

  bool visibilityOfNext = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        "Sorular İle Teşhis",
        style: Theme.of(context).textTheme.headline5,
      )),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                  border: Border.all(
                    width: 6,
                    color: Theme.of(context).colorScheme.primary,
                  )),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              child: Column(
                children: <Widget>[
                  Container(
                      padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                      child: Text(
                        "Sorulara uygun cevapları verdikten sonra kaydet tuşuna basınız. Ardından karşınıza çıkacak butona basarak cevaplarınızla ilgili hastalık hakkında bilgi edinebilirsiniz.",
                        style: Theme.of(context).textTheme.bodyText1,
                        textAlign: TextAlign.justify,
                      )),
                  CheckboxListTile(
                      activeColor: Theme.of(context).colorScheme.primary,
                      checkColor:
                          Theme.of(context).colorScheme.secondaryVariant,
                      title: Text(
                        "Sık sık öksürüyor mu?",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      value: coughing,
                      onChanged: (bool? newValue) {
                        setState(() {
                          coughing = newValue;
                        });
                      }),
                  CheckboxListTile(
                      activeColor: Theme.of(context).colorScheme.primary,
                      checkColor:
                          Theme.of(context).colorScheme.secondaryVariant,
                      title: Text(
                        "Sık sık hapşırıyor mu?",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      value: sneezing,
                      onChanged: (bool? newValue) {
                        setState(() {
                          sneezing = newValue;
                        });
                      }),
                  CheckboxListTile(
                      activeColor: Theme.of(context).colorScheme.primary,
                      checkColor:
                          Theme.of(context).colorScheme.secondaryVariant,
                      title: Text(
                        "Kafasını anormal olarak sallıyor mu?",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      value: shakingHead,
                      onChanged: (bool? newValue) {
                        setState(() {
                          shakingHead = newValue;
                        });
                      }),
                  CheckboxListTile(
                      activeColor: Theme.of(context).colorScheme.primary,
                      checkColor:
                          Theme.of(context).colorScheme.secondaryVariant,
                      title: Text(
                        "Nefes alırken hırıltı gibi olağandışı ses geliyor mu?",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      value: rales,
                      onChanged: (bool? newValue) {
                        setState(() {
                          rales = newValue;
                        });
                      }),
                  CheckboxListTile(
                      activeColor: Theme.of(context).colorScheme.primary,
                      checkColor:
                          Theme.of(context).colorScheme.secondaryVariant,
                      title: Text(
                        "Soluk alıp verirken zorluk yaşıyor mu?",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      value: gasping,
                      onChanged: (bool? newValue) {
                        setState(() {
                          gasping = newValue;
                        });
                      }),
                  CheckboxListTile(
                      activeColor: Theme.of(context).colorScheme.primary,
                      checkColor:
                          Theme.of(context).colorScheme.secondaryVariant,
                      title: Text(
                        "Gözlerinden iltihaplı sıvı salgılıyor mu?",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      value: eyeDischarge,
                      onChanged: (bool? newValue) {
                        setState(() {
                          eyeDischarge = newValue;
                        });
                      }),
                  CheckboxListTile(
                      activeColor: Theme.of(context).colorScheme.primary,
                      checkColor:
                          Theme.of(context).colorScheme.secondaryVariant,
                      title: Text(
                        "Burnundan/Genzinden iltihaplı sıvı salgılıyor mu?",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      value: nasalDischarge,
                      onChanged: (bool? newValue) {
                        setState(() {
                          nasalDischarge = newValue;
                        });
                      }),
                  CheckboxListTile(
                      activeColor: Theme.of(context).colorScheme.primary,
                      checkColor:
                          Theme.of(context).colorScheme.secondaryVariant,
                      title: Text(
                        "Yüzünde ve/veya ibiğinde şişme var mı?",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      value: swelling,
                      onChanged: (bool? newValue) {
                        setState(() {
                          swelling = newValue;
                        });
                      }),
                  CheckboxListTile(
                      activeColor: Theme.of(context).colorScheme.primary,
                      checkColor:
                          Theme.of(context).colorScheme.secondaryVariant,
                      title: Text(
                        "Yüzü mavimsi/morumsu bir renk almış durumda mı?",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      value: discoloration,
                      onChanged: (bool? newValue) {
                        setState(() {
                          discoloration = newValue;
                        });
                      }),
                  CheckboxListTile(
                      activeColor: Theme.of(context).colorScheme.primary,
                      checkColor:
                          Theme.of(context).colorScheme.secondaryVariant,
                      title: Text(
                        "Erişkinliğe varma süresi uzun mu?",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      value: retardedGrowth,
                      onChanged: (bool? newValue) {
                        setState(() {
                          retardedGrowth = newValue;
                        });
                      }),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        FloatingActionButton(
                          heroTag: null,
                          onPressed: () async {
                            List messageToShow2 =
                                await _myDatabaseConnection2.getDiseaseInfo2(
                              coughing: coughing,
                              sneezing: sneezing,
                              shakingHead: shakingHead,
                              rales: rales,
                              gasping: gasping,
                              eyeDischarge: eyeDischarge,
                              nasalDischarge: nasalDischarge,
                              swelling: swelling,
                              discoloration: discoloration,
                              retardedGrowth: retardedGrowth,
                            );

                            setState(() {
                              messageToShow = messageToShow2;
                              lengthOfMessageToShow = messageToShow!.length;

                              visibilityOfNext = true;
                              Logger().i(messageToShow);
                              Logger().i(lengthOfMessageToShow);
                            });
                          },
                          child: const Icon(Icons.save_rounded),
                          splashColor:
                              Theme.of(context).colorScheme.secondaryVariant,
                          tooltip: "Click to save your selections",
                        ),
                        Visibility(
                          visible: visibilityOfNext,
                          child: FloatingActionButton(
                            heroTag: null,
                            onPressed: () {
                              Navigator.pushNamed(context, "InfoPage2");
                            },
                            child: const Icon(Icons.arrow_forward_rounded),
                            tooltip: "Click to show results of your selections",
                            splashColor:
                                Theme.of(context).colorScheme.secondaryVariant,
                          ),
                        )
                      ]),
                ],
              )),
        ),
      ),
    );
  }
}

class MyFuture3 extends StatelessWidget {
  const MyFuture3({Key? key, required this.index}) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        // Title
        // Oswald bold?
        Container(
          margin: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: const BorderRadius.all(Radius.circular(15.0)),
              border: Border.all(
                width: 6,
                color: Theme.of(context).colorScheme.primary,
              )),
          alignment: Alignment.center,
          child: Text(
            "${_RadioPage1.messageToShow?[index]["diseaseName"]}",
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondary,
                fontSize: 50.0),
          ),
        ),
        // Text to Show
        Container(
            margin: const EdgeInsets.all(10.0),
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                border: Border.all(
                  width: 4.0,
                  color: Theme.of(context).colorScheme.primary,
                )),
            child: Text(
              "${_RadioPage1.messageToShow?[index]["text_to_show"]}",
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontSize: Theme.of(context).textTheme.bodyText1!.fontSize),
              textAlign: TextAlign.justify,
            ))
      ]),
    );
  }
}

class _InfoPage2 extends StatelessWidget {
  const _InfoPage2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Bilgilendirme Sayfası",
            style: Theme.of(context).textTheme.headline5,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SingleChildScrollView(
          child: Column(children: <Widget>[
            _RadioPage1.lengthOfMessageToShow! != 0
                ? SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        for (var i = 0;
                            i < _RadioPage1.lengthOfMessageToShow!;
                            i++)
                          MyFuture3(index: i)
                      ],
                    ),
                  )
                : Center(
                    child: Container(
                        margin:
                            const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
                        padding:
                            const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(15.0)),
                            border: Border.all(
                                width: 4.5,
                                color: Theme.of(context).colorScheme.primary)),
                        child: Center(
                            child: Column(children: [
                          Text("Girdinize ait kayıt bulunamamıştır.",
                              style: Theme.of(context).textTheme.bodyText1),
                          Text("Lütfen tekrar deneyiniz.",
                              style: Theme.of(context).textTheme.bodyText1)
                        ]))))
          ]),
        ));
  }
}
