#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

void setup() {
  Serial.begin(115200);
  Serial.println("Starting Foxhunt BLE Beacon!");

  // Initialize the BLE device with the EXACT name our Flutter app is looking for
  BLEDevice::init("FOXHUNT_01");

  // Create the BLE Server (required to advertise)
  BLEServer *pServer = BLEDevice::createServer();

  // Configure the advertising packet
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  
  // Add a generic UUID so scanners can categorize it
  pAdvertising->addServiceUUID("12345678-1234-1234-1234-1234567890AB");
  pAdvertising->setScanResponse(true);
  
  // These parameters optimize discovery speed for smartphones (iOS/Android)
  pAdvertising->setMinPreferred(0x06);  
  pAdvertising->setMinPreferred(0x12);
  
  // Begin broadcasting the signal!
  BLEDevice::startAdvertising();
  Serial.println("Beacon active! The Flutter app should now detect 'FOXHUNT_01'.");
}

void loop() {
  // The ESP32 handles BLE broadcasting in the background. 
  // We don't need to do anything in the main loop!
  delay(2000);
}
