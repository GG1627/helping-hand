import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'word_sequence.dart';

class TfliteWordClassifier implements WordClassifier {
  TfliteWordClassifier({String? target})
    : _directory = additionalPracticeWords.contains(target)
          ? _expandedDirectory
          : _wordDirectory,
      _motionLetters = false;
  TfliteWordClassifier.motionLetters()
    : _directory = _motionDirectory,
      _motionLetters = true;

  static const _wordDirectory = 'assets/models/words_tcn';
  static const _expandedDirectory = 'assets/models/expanded_words_tcn';
  static const _motionDirectory = 'assets/models/motion_letters_tcn';
  static const modelAsset = '$_wordDirectory/model.tflite';
  static const metadataAsset = '$_wordDirectory/model_metadata.json';
  final String _directory;
  final bool _motionLetters;
  Uint8List? _modelBytes;
  WordModelSpec? _spec;
  bool _disposed = false;

  @override
  Future<void> initialize() async {
    final spec = WordModelSpec.fromJson(
      jsonDecode(await rootBundle.loadString('$_directory/model_metadata.json'))
          as Map<String, dynamic>,
      motionLetters: _motionLetters,
      wordVocabulary: _directory == _expandedDirectory
          ? expandedWordVocabulary
          : trainedWords,
    );
    final data = await rootBundle.load('$_directory/model.tflite');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    if (_disposed) return;
    final interpreter = Interpreter.fromBuffer(
      bytes,
      options: InterpreterOptions()..threads = 1,
    );
    try {
      if (!listEquals(interpreter.getInputTensor(0).shape, [
            1,
            spec.windowSamples,
            spec.featureCount,
          ]) ||
          !listEquals(interpreter.getOutputTensor(0).shape, [
            1,
            spec.vocabulary.length,
          ]) ||
          interpreter.getInputTensor(0).type != TensorType.float32 ||
          interpreter.getOutputTensor(0).type != TensorType.float32) {
        throw const FormatException('Incompatible word model tensors.');
      }
      _modelBytes = bytes;
      _spec = spec;
    } finally {
      interpreter.close();
    }
  }

  @override
  Future<WordPrediction> predict(List<WordFrame> frames) async {
    final spec = _spec;
    final bytes = _modelBytes;
    if (_disposed || spec == null || bytes == null) {
      throw StateError('Word model is not ready.');
    }
    // Each user-delimited attempt owns its interpreter inside the worker.
    // Errors propagate normally and leaving the page cannot free a live pointer.
    final result = await compute(
      _inferWord,
      _WordInferenceRequest(
        bytes,
        spec.prepare(frames),
        spec.vocabulary.length,
      ),
    );
    return WordPrediction.fromProbabilities(
      result.probabilities,
      spec.vocabulary,
      inferenceMs: result.elapsedMs,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _modelBytes = null;
    _spec = null;
  }
}

class _WordInferenceRequest {
  const _WordInferenceRequest(this.bytes, this.input, this.classCount);
  final Uint8List bytes;
  final List<List<double>> input;
  final int classCount;
}

class _WordInferenceResult {
  const _WordInferenceResult(this.probabilities, this.elapsedMs);
  final List<double> probabilities;
  final double elapsedMs;
}

_WordInferenceResult _inferWord(_WordInferenceRequest request) {
  final watch = Stopwatch()..start();
  final interpreter = Interpreter.fromBuffer(
    request.bytes,
    options: InterpreterOptions()..threads = 1,
  );
  try {
    final output = [List<double>.filled(request.classCount, 0)];
    interpreter.run([request.input], output);
    return _WordInferenceResult(
      output.single,
      watch.elapsedMicroseconds / 1000,
    );
  } finally {
    interpreter.close();
  }
}
