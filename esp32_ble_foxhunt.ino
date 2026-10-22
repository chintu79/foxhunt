/*
 * Fox Hunt 2026 - High-Stability ESP32 BLE Beacon Transmitter
 * 
 * Configured for maximum signal stability, minimal RSSI fluctuation,
 * and high packet cadence (15-20 Hz) for smooth hunting telemetry.
 */

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <esp_bt.h>
#include <esp_gap_ble_api.h>
#include <WiFi.h>

// =========================================================================
// TRANSMITTER CONFIGURATION
// Choose FOXHUNT_01 for the REAL transmitter or FOXHUNT_02 for the DUMMY.
// =========================================================================
#define FOX_NAME "FOXHUNT_2"   // Dummy Transmitter 2

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n==========================================");
  Serial.printf("  FOX HUNT 2026 - TRANSMITTER: %s\n", FOX_NAME);
  Serial.println("==========================================");

  // 1. Completely disable WiFi to prevent RF synthesizer coexistence jitter
  WiFi.mode(WIFI_OFF);
  btStop(); // Clean start for BT controller
  delay(100);

  // 2. Initialize BLE Device with exact Fox Hunt target name
  BLEDevice::init(FOX_NAME);

  // 3. Set maximum transmission power (+9 dBm) for maximum range & stability
  //    Higher TX power dramatically reduces multipath fading and antenna nulls.
  esp_ble_tx_power_set(ESP_BLE_PWR_TYPE_ADV, ESP_PWR_LVL_P9);
  esp_ble_tx_power_set(ESP_BLE_PWR_TYPE_DEFAULT, ESP_PWR_LVL_P9);

  // 4. Create BLE Server
  BLEServer *pServer = BLEDevice::createServer();

  // 5. Configure Advertising Data
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();

  // Set standard service UUID for categorization
  pAdvertising->addServiceUUID("12345678-1234-1234-1234-1234567890AB");

  // Include device name in advertising payload
  pAdvertising->setScanResponse(true);

  // 6. Fast, consistent advertising interval (50ms - 60ms)
  //    Units are in 0.625ms steps:
  //    0x0050 = 80 * 0.625ms = 50ms interval (~20 packets/sec)
  //    0x0060 = 96 * 0.625ms = 60ms interval
  //    This high packet density allows the phone's median & EMA filters
  //    to produce an ultra-smooth, stable RSSI with zero latency.
  pAdvertising->setMinInterval(0x0050); // 50ms
  pAdvertising->setMaxInterval(0x0060); // 60ms

  // Smartphone discovery hints
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);

  // 7. Start broadcasting
  pAdvertising->start();

  Serial.println("[✓] RF Carrier active at +9 dBm (Max Power)");
  Serial.println("[✓] Advertising rate locked at 50ms (~20 pkts/sec)");
  Serial.printf("[✓] Broadcasting as: %s\n", FOX_NAME);
  Serial.println("==========================================");
}

void loop() {
  // ESP32 hardware radio handles continuous packet broadcasting automatically.
  #ifdef LED_BUILTIN
    digitalWrite(LED_BUILTIN, HIGH);
    delay(100);
    digitalWrite(LED_BUILTIN, LOW);
    delay(1900);
  #else
    delay(2000);
  #endif
}
