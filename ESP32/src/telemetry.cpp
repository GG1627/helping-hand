#include "telemetry.h"
#include <stdio.h>

// KALI ADDED A CHANGE SO SHE CAN COMMIT THIS IM GOING CRAZZZZYYY

using namespace std;

void formatTelemetry(char* payload, size_t capacity, uint64_t packetSequence,
                     uint64_t deviceTimestampMs, uint8_t imuWhoAmI,
                     const ImuSample& sample, bool imuSampleOk,
                     const FlexReadings& flex, const char* expectedLabel,
                     const char* predictedLabel, float predictedConfidence,
                     bool predictionOk) {
  if (imuSampleOk) {
    snprintf(
      payload,
      capacity,
      "seq=%llu,t_ms=%llu,who=0x%02X,ax=%.3f,ay=%.3f,az=%.3f,gx=%.3f,gy=%.3f,gz=%.3f,expected=%s,pred=%s,pred_conf=%.1f,flex0_raw=%d,flex0_norm=%.3f,flex1_raw=%d,flex1_norm=%.3f,flex2_raw=%d,flex2_norm=%.3f,flex3_raw=%d,flex3_norm=%.3f,flex4_raw=%d,flex4_norm=%.3f",
      static_cast<unsigned long long>(packetSequence),
      static_cast<unsigned long long>(deviceTimestampMs),
      imuWhoAmI,
      sample.axG,
      sample.ayG,
      sample.azG,
      sample.gxDps,
      sample.gyDps,
      sample.gzDps,
      expectedLabel,
      predictionOk ? predictedLabel : "NA",
      predictionOk ? predictedConfidence : 0.0f,
      flex.raw[0],
      flex.norm[0],
      flex.raw[1],
      flex.norm[1],
      flex.raw[2],
      flex.norm[2],
      flex.raw[3],
      flex.norm[3],
      flex.raw[4],
      flex.norm[4]
    );
  } else {
    snprintf(
      payload,
      capacity,
      "seq=%llu,t_ms=%llu,imu=offline,expected=%s,pred=%s,pred_conf=%.1f,flex0_raw=%d,flex0_norm=%.3f,flex1_raw=%d,flex1_norm=%.3f,flex2_raw=%d,flex2_norm=%.3f,flex3_raw=%d,flex3_norm=%.3f,flex4_raw=%d,flex4_norm=%.3f",
      static_cast<unsigned long long>(packetSequence),
      static_cast<unsigned long long>(deviceTimestampMs),
      expectedLabel,
      predictionOk ? predictedLabel : "NA",
      predictionOk ? predictedConfidence : 0.0f,
      flex.raw[0],
      flex.norm[0],
      flex.raw[1],
      flex.norm[1],
      flex.raw[2],
      flex.norm[2],
      flex.raw[3],
      flex.norm[3],
      flex.raw[4],
      flex.norm[4]
    );
  }

}
