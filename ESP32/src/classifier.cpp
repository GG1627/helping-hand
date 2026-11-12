#include "classifier.h"
#include "flex_sensors.h"
#include <math.h>
#if HH_USE_RECORDED_STATIC_MODEL
#include "recorded_static_model_data.h"
#else
#include "asl_model_data.h"
#endif
#include "tensorflow/lite/c/common.h"
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"

using namespace std;

namespace {
constexpr int kModelInputSize = 5;
#if HH_USE_RECORDED_STATIC_MODEL
constexpr int kModelClassCount = kRecordedClassCount;
#else
constexpr int kModelClassCount = 36;
#endif
constexpr size_t kTensorArenaSize = 70 * 1024;
alignas(16) uint8_t tensorArena[kTensorArenaSize];

const tflite::Model* mlModel = nullptr;
tflite::AllOpsResolver mlResolver;
tflite::MicroErrorReporter mlMicroErrorReporter;
tflite::ErrorReporter* mlErrorReporter = &mlMicroErrorReporter;
tflite::MicroInterpreter* mlInterpreter = nullptr;
TfLiteTensor* mlInputTensor = nullptr;
TfLiteTensor* mlOutputTensor = nullptr;
bool mlReady = false;

#if HH_USE_RECORDED_STATIC_MODEL
const float* const kFeatureMean = kRecordedFeatureMean;
const float* const kFeatureScale = kRecordedFeatureScale;
const char* const* const kClassLabels = kRecordedClassLabels;
#else
const float kFeatureMean[kModelInputSize] = {
  294.58229166666666f,
  416.1657986111111f,
  345.5805555555556f,
  260.7661458333333f,
  260.40746527777776f
};

const float kFeatureScale[kModelInputSize] = {
  111.92435518526472f,
  164.16211005855075f,
  178.97278299358564f,
  154.56913119757505f,
  185.51501168995773f
};

const char* kClassLabels[kModelClassCount] = {
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
  "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
  "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
  "U", "V", "W", "X", "Y", "Z"
};
#endif

struct MlTestCase {
  const char* expected;
  int flex[kModelInputSize];
};

const MlTestCase kMlTestCases[] = {
  {"N", {145, 135, 130, 125, 95}},      // FIST-LIKE SAMPLE FROM DEMO CALIBRATION RANGE
  {"5", {550, 550, 550, 550, 560}},     // ALL FINGERS EXTENDED
  {"1/Z", {145, 550, 130, 125, 95}},    // INDEX UP
};

void writeInputFeature(int index, float value) {
  if (mlInputTensor->type == kTfLiteFloat32) {
    mlInputTensor->data.f[index] = value;
    return;
  }

  if (mlInputTensor->type == kTfLiteInt8) {
    const float scale = mlInputTensor->params.scale;
    const int zeroPoint = mlInputTensor->params.zero_point;
    const int q = static_cast<int>(roundf(value / scale)) + zeroPoint;
    mlInputTensor->data.int8[index] = static_cast<int8_t>(constrain(q, -128, 127));
  }
}

float readOutputProbability(int index) {
  if (mlOutputTensor->type == kTfLiteFloat32) {
    return mlOutputTensor->data.f[index];
  }

  if (mlOutputTensor->type == kTfLiteInt8) {
    const float scale = mlOutputTensor->params.scale;
    const int zeroPoint = mlOutputTensor->params.zero_point;
    return (static_cast<int>(mlOutputTensor->data.int8[index]) - zeroPoint) * scale;
  }

  return 0.0f;
}

}

bool setupClassifier() {
  mlModel = tflite::GetModel(g_asl_model_tflite);
  if (mlModel == nullptr) {
    Serial.println("GetModel failed.");
    return false;
  }

  static tflite::MicroInterpreter staticInterpreter(
    mlModel,
    mlResolver,
    tensorArena,
    kTensorArenaSize,
    mlErrorReporter,
    nullptr,
    nullptr
  );
  mlInterpreter = &staticInterpreter;

  const TfLiteStatus allocStatus = mlInterpreter->AllocateTensors();
  if (allocStatus != kTfLiteOk) {
    Serial.println("AllocateTensors failed.");
    return false;
  }

  mlInputTensor = mlInterpreter->input(0);
  mlOutputTensor = mlInterpreter->output(0);
  if (mlInputTensor == nullptr || mlOutputTensor == nullptr) {
    Serial.println("TFLite tensors unavailable.");
    return false;
  }

  const int inputFeatures = mlInputTensor->dims->data[mlInputTensor->dims->size - 1];
  const int outputClasses = mlOutputTensor->dims->data[mlOutputTensor->dims->size - 1];
  if (inputFeatures != kModelInputSize || outputClasses != kModelClassCount) {
    Serial.printf(
      "Unexpected tensor shape. in=%d out=%d expected in=%d out=%d\n",
      inputFeatures,
      outputClasses,
      kModelInputSize,
      kModelClassCount
    );
    return false;
  }

  mlReady = true;
  Serial.printf("Static model: %s (%d classes)\n",
                HH_USE_RECORDED_STATIC_MODEL ? "real recorded MLP" : "synthetic baseline",
                kModelClassCount);
  Serial.printf("TFLite ready. Input type=%d Output type=%d\n", mlInputTensor->type, mlOutputTensor->type);
  return true;
}

bool classifyFlex(const FlexReadings& flex, FlexPrediction& prediction) {
  prediction = FlexPrediction{};
  if (!mlReady || mlInterpreter == nullptr) return false;

  for (int i = 0; i < kModelInputSize; i++) {
    const float modelValue = flexModelInput(i, flex.raw[i]);
    const float normalized = (modelValue - kFeatureMean[i]) / kFeatureScale[i];
    writeInputFeature(i, normalized);
  }

  if (mlInterpreter->Invoke() != kTfLiteOk) {
    return false;
  }

  int bestIndex = 0;
  float bestProb = readOutputProbability(0);
  int bestLetter = -1;
  int bestNumber = -1;
  float bestLetterProb = -1.0f;
  float bestNumberProb = -1.0f;
  for (int i = 0; i < kModelClassCount; i++) {
    const float p = readOutputProbability(i);
    if (!isfinite(p) || p < 0.0f || p > 1.00001f) return false;
    if (p > bestProb) {
      bestProb = p;
      bestIndex = i;
    }
    const char label = kClassLabels[i][0];
    if (label >= 'A' && label <= 'Z' && p > bestLetterProb) {
      bestLetter = i;
      bestLetterProb = p;
    } else if (label >= '0' && label <= '9' && p > bestNumberProb) {
      bestNumber = i;
      bestNumberProb = p;
    }
  }

  prediction.overall = {kClassLabels[bestIndex], bestProb * 100.0f};
  if (bestLetter >= 0) prediction.letter = {kClassLabels[bestLetter], bestLetterProb * 100.0f};
  if (bestNumber >= 0) prediction.number = {kClassLabels[bestNumber], bestNumberProb * 100.0f};
  return true;
}

const char* applyClassifierTestInput(FlexReadings& flex) {
  const char* expectedLabel = "-";
  if (kUseHardcodedMlTest) {
    const size_t caseCount = sizeof(kMlTestCases) / sizeof(kMlTestCases[0]);
    const size_t caseIndex = (millis() / 2000) % caseCount;  // switch every 2s
    expectedLabel = kMlTestCases[caseIndex].expected;
    for (int i = 0; i < kModelInputSize; i++) {
      flex.raw[i] = kMlTestCases[caseIndex].flex[i];
      flex.norm[i] = readFlexNormalized(flex.raw[i]);
    }
  }
  return expectedLabel;
}
