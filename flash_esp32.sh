#!/bin/bash
echo "Starting ESP32-C3 Flash Process..."
sudo /home/doanchim/.arduino15/packages/esp32/tools/esptool_py/5.2.0/esptool --chip esp32c3 --port /dev/ttyACM0 --baud 460800 write-flash 0x0 /home/doanchim/doantotnhiep/doantotnghiep/build_esp32/health_esp32.ino.merged.bin
echo "Done! Please reset your ESP32."
