# Helping Hand Release Candidate

### M5 Milestone Work Outline

**Course:** CEN 4908C

**Team:** Brian, Gael, Kali, Srinitha

**Repository Snapshot:** October 28, 2026; RC Commit [`ff6a9ab`](https://github.com/GG1627/helping-hand/commit/ff6a9ab763f12f60e3a327d0df4f00a8784894b8)

### Work Completed

- **Nine-axis IMU design and firmware:** We changed our planned IMU from the
  current six-axis unit to the Adafruit ICM-20948 nine-axis breakout, which adds
  a three-axis magnetometer. We updated the firmware to detect and initialize
  the new IMU, read its accelerometer and gyroscope, and read the AK09916
  magnetometer. The older MPU-style sensor is still supported. Magnetic
  readings are available through serial diagnostics; the current BLE motion
  fields and word model still use accelerometer/gyroscope data. Installing the
  new board, calibration, and orientation correction are still pending.

- **Piezo control code:** We added pin setup and timed PWM control for all ten
  piezo buzzers: one on each finger and five in an X on the back of the hand.
  All outputs start off, and the code can play one buzzer at a time without
  blocking the sensor/BLE loop. The firmware also checks for repeated pins or
  conflicts with the flex sensors and I2C connections. Connecting the buzzers
  to automatic finger corrections and testing the driver circuit are still
  pending.

- **PCB schematic and layout planning:** We continued the KiCad schematic for
  the ESP32-S3 and 15 resistors used in the five flex-sensor and ten piezo
  circuits. We have also been planning the board layout. Placement, routing,
  fabrication, and testing of the finished PCB are not complete.

- **Glove layout and sewing preparation:** We planned the placement of one IMU,
  five flex sensors, and ten piezos, and practiced making small circuits with
  conductive thread. The proposed layout puts a flex sensor and piezo at each
  finger, the IMU on a secured mount on the back of the hand, and five piezos
  in the dorsal X pattern. We plan to secure components with nonconductive
  stitching and use fabric channels so the flex strips can bend without
  pulling on their terminals. Sewing the full assembly is still pending.

- **Fabric insulation plan:** We proposed five fabric layers total, including
  the glove liner: inner liner, first routing fabric, insulating separator,
  second routing fabric, and outer cover. The two routing levels let us
  separate connections where they cross. Each routing fabric will be sewn
  separately so conductive stitches do not pass through the separator into
  the other level. Terminals, knots, and extra crossings still need local
  insulation. Five layers is a starting design, not a tested minimum or a
  guarantee against shorts; the final wiring layout may need adjustments.
  We plan to use insulated flexible wire for IMU I2C and power connections
  and check continuity and shorts with the glove flat and bent before powering it.

- **Flex-sensor replacement planning:** About two flex sensors were reading
  bent when straight. We ordered five Adafruit Short Flex Sensor #1070
  replacements. Repair and recalibration are needed before collecting reliable
  new recordings; installation has not been confirmed.

- **TCN improvement review:** We reviewed ways to improve the existing word
  model, including collecting more repetitions across wearers and wrist angles,
  retaining more of each complete gesture, and rejecting idle or unrelated
  movement. These are proposed changes, not a newly trained model or a measured
  accuracy improvement. Hello, Please, and Yes recognition is carried forward
  from M4.

- **Firmware checks:** Host-side simulated-I2C checks passed for the new IMU's
  register setup, signed sensor values and units, magnetometer readiness and
  overflow handling, reconnect behavior, the older sensor path, and address
  0x69. These are software checks. The full ESP32 build attempt timed out while
  PlatformIO tried to install a missing tool; board compilation and physical
  testing of the new IMU are not confirmed.

- **Release documentation:** We updated the release-candidate README with the
  M5 rubric table, current hardware plans, piezo pin assignments, and the work
  still needing testing. The existing account flow, saved progress, dedicated
  practice pages, and three-word TCN are retained from the beta build rather
  than counted as new M5 features. New-board bring-up, buzzer output, sewn-glove
  checks, and current glove-to-phone testing are **Not run**.
