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

/* NOTES

There are 2 ways to finish this project and get ready to be in the expedition:
***Using pytorch with flutter:
-https://pub.dev/packages/pytorch_mobile
-https://pytorch.org/mobile/android/
-https://github.com/pytorch/workshops/tree/master/PTMobileWalkthruAndroid

You should first prepare the pytorch model and implement the flutter side of it. 

***Converting pytorch model to tflite:
-https://github.com/gmalivenko/pytorch2keras
-https://learnopencv.com/pytorch-to-tensorflow-model-conversion/

You should convert the pytorch model to .tf format. And then to .tflite format.


-Checking the .tflite models acc:
*https://github.com/tensorflow/tensorflow/tree/master/tensorflow/lite/tools/evaluation/tasks

-Optimization of models:
*https://www.tensorflow.org/lite/performance/model_optimization?hl=en
*https://www.tensorflow.org/lite/performance/post_training_quant?hl=en

-What is metadata? And do I need it? 
*https://www.tensorflow.org/lite/convert/metadata?hl=en

There are 3 lib options to use tflite:
1) tflite
Note: tflite plugin returns an error: The plugin `tflite` uses a deprecated version of the Android embedding.
To avoid unexpected runtime failures, or future build failures, try to see if this plugin supports the Android 
V2 embedding. Otherwise, consider removing it since a future release of Flutter will remove these deprecated APIs.

2) tflite_flutter
3) tflite_flutter_helper

I'm using 3rd option. I tried the 1st option but I was debugging it with Chrome. And as far as 
I remember there was a problem with that. I don't quite remember it but it wasn't working.
After that I used it in Virtual Device (VD) and there was another problem as well. 
If I decide to change the library I used, I'll use tflite. I'm providing some links:
*https://pub.dev/packages/tflite
*https://spltech.co.uk/flutter-image-classification-using-tensorflow-in-4-steps/

-I've downloaded both commandline-tools and sdkmanager for android studio +
-I think if I use an android emulator there won't be a problem with the tflite lib
or tflite_flutter lib. +

TO DO:
-Figure out the NormalizeOP variables in classifier_get.dart

-Now is the time for keyword search part. You have 3 table to work with. First implement the first one.
You are going to create a table named table1. You are going to implement the table t databese basically.
Then you are going to display radio buttons at keywords page and a next button. This way you are going to 
get boolens of symptoms. After that it is just filtering. There is a problem here though. There might be 2 disease
that has exactly the same sypmtoms. You can solve this problem by doing this: when you retrive the maps data,
you are going to check the number of elements in it. If it is bigger than 1 you are going to display all of
them back-to-back. 

-Implement database structure. +
*You are going to do this by creating a read-only database in the assets folder. 
Then you are going to get data from it. If you need the update the data (eg. new disease 
has been trained) you just going to update te database.db and model.tflite! 
*https://stackoverflow.com/questions/51384175/sqlite-in-flutter-how-database-assets-work/51387985#51387985
*https://stackoverflow.com/questions/55167439/flutter-where-to-put-own-sqlite-db-file
*https://blog.devgenius.io/adding-sqlite-db-file-from-the-assets-internet-in-flutter-3ec42c14cd44

-Implement ThemeData! +

-learn how to get to the another page. I can do predictions and get the predictions confidence.
I'm going to show lossa text. +

-learn how to be mobile-compatiple as much as possible
      width: MediaQuery.of(context).size.width * 0.35,
      height: MediaQuery.of(context).size.height * 0.2, 
MediaQuery might be the way!

-you may want to look this site later (in semestr maybe): https://flutterbyexample.com/ 

-try using tflite_flutter and make it work son! +

-Some sites for tflite_flutter and tflite_flutter_helper:
*https://github.com/am15h/tflite_flutter_helper
*https://github.com/am15h/tflite_flutter_helper/tree/master/example/image_classification/lib
*/

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
          primaryColor: HexColor("#0336FF"), //primary: blue
          //colorScheme: ColorScheme(primary: HexColor("#0336FF") ),
          canvasColor: HexColor("#FFDE03"), //secondary: yellow
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
            //drawer: Drawer(
            //  //backgroundColor: Palette._bgColor,
            //  child: ListView(
            //    padding: EdgeInsets.zero,
            //    children: [
            //      DrawerHeader(
            //        decoration: BoxDecoration(
            //          color: Theme.of(context).backgroundColor,
            //        ),
            //        child: Text(
            //          "Disease Finder",
            //          style: Theme.of(context).textTheme.headline4,
            //        ),
            //      ),
            //      ListTile(
            //        title: Text(
            //          "Exit",
            //          style: Theme.of(context).textTheme.headline6,
            //        ),
            //        onTap: () => exit(0),
            //      ),
            //    ],
            //  ),
            //),
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
      //_predict2();
      //logger.i("[INFO] Prediction2 has been made.");
    });
  }

/*  Future classifyImage() async {
    //Image Classifier using tflite lib
    print("[INFO] Model is being loaded.");
    await Tflite.loadModel(model: 'model2.tflite', labels: 'labels.txt');
    print("[INFO] Problem occured while loading the model!");
    print("[INFO] Model has loaded.");
    final output = await Tflite.runModelOnImage(path: imagesPath!);
    print("[INFO] There is an output to print!");
    print("This is the output: ");
    print(output);
    setState(() {
      outputOfCNN = output; // output's type is List
      /*{
          index: 0,
          label: "person",    OUTPUT'S FORMAT
          confidence: 0.629
        } */
      _nextButisDisabled = false;
      _loading = true;
    });
  }
*/

/*  Future classifyImage2() async {
    //Image Classifier using tflite_flutter and tflite_flutter_helper lib
    final interpreter = await Interpreter.fromAsset('model2.tflite');

    // For ex: if input tensor shape [1,5] and type is float32
    var input = [1.23];

    // if output tensor shape [1,2] and type is float32
    var outputFormat = List.filled(1 * 2, 0).reshape([1, 2]);

    // inference
    interpreter.run(input, outputFormat);

    // print the output
    print(outputFormat);

    interpreter.close();

    setState(() {
      outputOfCNN = outputFormat;
    });
    return;
  }
*/

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
              //FloatingActionButton(
              //    backgroundColor: Theme.of(context).colorScheme.primary,
              //    heroTag: null,
              //    onPressed: () {
              //      try {
              //        //_predictTORCH();
              //      } catch (e) {
              //        Navigator.pushNamed(context, "ViaPhoto");
              //      }
              //    },
              //    tooltip: "DEBUG",
              //    child: const Icon(Icons.dangerous_outlined),
              //    foregroundColor: Theme.of(context).colorScheme.onPrimary)
            ], //
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
