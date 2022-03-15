import 'package:imagepick/classifier.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class ClassifierGet extends Classifier {
  ClassifierGet({int numThreads = 1}) : super(numThreads: numThreads);

  @override
  String get modelName => 'modelMobileNet2.tflite';

  @override
  NormalizeOp get preProcessNormalizeOp => NormalizeOp(127.5, 127.5);
  // I should examine this values

  @override
  NormalizeOp get postProcessNormalizeOp => NormalizeOp(0, 1);
}
