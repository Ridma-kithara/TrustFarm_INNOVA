#pragma once
// ---- EDIT THESE (do not commit real credentials) ----
#define WIFI_SSID      "your-wifi"
#define WIFI_PASS      "your-wifi-password"
#define MQTT_HOST      "192.168.1.10"     // machine running docker compose
#define MQTT_PORT      1883
#define MQTT_USER      "esp32-zone1"
#define MQTT_PASS      "device-password"
#define ZONE_ID        1

// ---- Pins ----
#define PIN_SOIL1      34
#define PIN_SOIL2      35
#define PIN_RAIN       32
#define PIN_FLOW       27
#define PIN_DHT        4

// ---- Calibration (measure RAW in air = dry, RAW in water = wet) ----
#define SOIL_RAW_DRY   3200
#define SOIL_RAW_WET   1300
#define RAIN_RAW_DRY   4095
#define RAIN_RAW_WET   1500
#define FLOW_PULSES_PER_L 450.0f   // YF-S201 approx; calibrate

// ---- Battery (12 V lead-acid, rough open-circuit estimate) ----
#define BATT_V_EMPTY   11.8f
#define BATT_V_FULL    12.8f

#define PUBLISH_MS     60000UL
#define BUFFER_SIZE    60          // store-and-forward during network loss
