# Helping Hand Release Candidate

### M5 Milestone Work Outline

**Course:** CEN 4908C

**Team:** Brian, Gael, Kali, Srinitha

**Repository Snapshot:** October 28, 2026; RC commit not yet selected.

### Work Completed

- **IMU design change and firmware:** We changed our planned hardware from the
  current six-axis IMU to an Adafruit ICM-20948 nine-axis breakout. The new part
  adds a three-axis magnetometer alongside the accelerometer and gyroscope.
  We updated the firmware to identify the ICM-20948, use its register banks,
  configure the accelerometer/gyroscope, and read its AK09916 magnetometer.
  The older MPU-style sensor path is still supported. Magnetic readings are
  available through serial diagnostics; the app's BLE motion fields and
  current word model still use accelerometer/gyroscope data. Calibration,
  orientation fusion, and testing on the new board are still pending.

- **Piezo firmware:** We added pin setup and timed PWM control for all ten
  piezo buzzers: five on the fingers and five in an X on the back of the hand.
  The code can play one buzzer at a time and stop it without blocking the
  sensor/BLE loop. The outputs stay off at startup. We still need to connect
  the cues to finger corrections and test the actual buzzers and driver circuit.

- **PCB schematic:** We continued the KiCad schematic for the ESP32-S3 and
  15 resistors used in the five flex-sensor and ten piezo circuits. We have
  also been planning the board layout. Routing, fabrication, and testing of
  the finished board are not complete.

- **Glove layout and sewing preparation:** We began planning the placement of
  one IMU, five flex sensors, and ten piezos, and practiced sewing small
  circuits with conductive thread. The plan places a flex sensor and piezo
  at each finger, the IMU on a secured mount on the back of the hand, and the
  remaining five piezos in the dorsal X pattern. The flex sensors need fabric
  channels that let their sensing strips bend without pulling on the terminals.
  Components will be held with nonconductive stitching and their connections
  insulated separately.

- **Fabric-layer plan:** Our proposed starting layout has **five fabric layers
  total, including the glove liner**: the inner liner, one routing fabric,
  an insulating separator, a second routing fabric, and an outer cover. This
  gives us two separate routing levels for connections that need to cross.
  We will sew each routing fabric separately so conductive stitches do not
  pass through the separator and touch the other level. Exposed terminals,
  knots, and any extra crossings still need local insulation. Five layers is
  a design proposal, not a tested minimum or a guarantee against shorts.
  The final count depends on the drawn wiring routes and fabric thickness.
  Before powering the glove, we need continuity/short checks while the glove
  is flat and while the fingers are bent. Insulated flexible wire is preferred
  for IMU I2C and power connections, where conductive-thread resistance and
  movement could affect the connection.

- **Sensor replacement and model planning:** About two existing flex sensors
  were reading bent when straight. We ordered five replacements and reviewed
  TCN improvements, including collecting more data, keeping more of each
  gesture, and rejecting unrelated movement. These changes still need fresh
  recordings and evaluation after the glove is repaired; no new accuracy gain
  has been measured.

- **Documentation:** We updated the release-candidate README with the current
  feature status, M5 rubric table, piezo pin assignments, and remaining tests.
  The beta account flow, saved progress, dedicated practice pages, and
  Hello/Please/Yes TCN are carried forward from M4 rather than claimed as new
  M5 features.

### Verification

Host-side simulated-I2C checks passed for ICM register setup, signed motion and
magnetic units, not-ready/overflow handling, reconnect, the older sensor path,
and address 0x69. Run `python3 ESP32/test/imu_host_test.py` with `g++` installed.
These checks do not replace an ESP32 build or physical testing. The full build
attempt timed out while PlatformIO tried to install the missing
`tool-openocd-esp32` package; board compilation is not confirmed. New-board
bring-up, magnetic calibration, sewn-glove checks, buzzer output, and current
end-to-end glove/phone testing are **Not run**.

### Design References

- [TDK ICM-20948 datasheet](https://product.tdk.com/system/files/dam/doc/product/sensor/mortion-inertial/imu/data_sheet/ds-000189-icm-20948-v1.5.pdf): register map and sensor scaling.
- [SparkFun: Sewing with Conductive Thread](https://learn.sparkfun.com/tutorials/sewing-with-conductive-thread/all?print=1): conductive thread is uninsulated; crossings need insulation.
- [SparkFun: Insulation Techniques for e-Textiles](https://sparkfuneducation.com/how-to/etextile-insulation.html): fabric liners/covers and securing insulation against movement. The five-layer layout above is our proposed arrangement, not a prescribed layer count from this guide.
