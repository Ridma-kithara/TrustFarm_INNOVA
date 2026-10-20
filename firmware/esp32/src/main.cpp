#include <Arduino.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <Adafruit_INA219.h>
#include <time.h>
#include "config.h"

DHT dht(PIN_DHT, DHT22);
Adafruit_INA219 inaGen(0x40);   // generator/charger side
Adafruit_INA219 inaLoad(0x41);  // farm load side
bool inaGenOk = false, inaLoadOk = false;

WiFiClient net;
PubSubClient mqtt(net);
String topic = String("trustfarm/zone/") + ZONE_ID + "/telemetry";

volatile uint32_t flowPulses = 0;
void IRAM_ATTR onFlow() { flowPulses++; }

// ---- RAM ring buffer for messages that could not be sent ----
String buf[BUFFER_SIZE];
int bufHead = 0, bufCount = 0;
void bufPush(const String &s) {
  buf[(bufHead + bufCount) % BUFFER_SIZE] = s;
  if (bufCount < BUFFER_SIZE) bufCount++;
  else bufHead = (bufHead + 1) % BUFFER_SIZE;  // overwrite oldest
}

float soilPercent(int raw) {
  float p = 100.0f * (SOIL_RAW_DRY - raw) / (float)(SOIL_RAW_DRY - SOIL_RAW_WET);
  return constrain(p, 0.0f, 100.0f);
}

int readAvg(int pin, int n = 16) {
  long s = 0;
  for (int i = 0; i < n; i++) { s += analogRead(pin); delay(2); }
  return s / n;
}

float battSoc(float v) {
  return constrain(100.0f * (v - BATT_V_EMPTY) / (BATT_V_FULL - BATT_V_EMPTY), 0.0f, 100.0f);
}

void connectWifi() {
  if (WiFi.status() == WL_CONNECTED) return;
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  uint32_t t = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - t < 10000) delay(250);
}

bool connectMqtt() {
  if (mqtt.connected()) return true;
  if (WiFi.status() != WL_CONNECTED) return false;
  String id = String("esp32-zone") + ZONE_ID;
  return mqtt.connect(id.c_str(), MQTT_USER, MQTT_PASS);
}

void flushBuffer() {
  while (bufCount > 0 && mqtt.connected()) {
    String &s = buf[bufHead];
    if (!mqtt.publish(topic.c_str(), s.c_str())) break;
    bufHead = (bufHead + 1) % BUFFER_SIZE;
    bufCount--;
    mqtt.loop();
    delay(50);
  }
}

String buildMessage() {
  JsonDocument d;
  time_t now = time(nullptr);
  if (now > 1700000000) d["ts"] = (double)now;   // only send a time we trust (NTP synced)

  d["soil1"] = serialized(String(soilPercent(readAvg(PIN_SOIL1)), 1));
  d["soil2"] = serialized(String(soilPercent(readAvg(PIN_SOIL2)), 1));

  float t = dht.readTemperature(), h = dht.readHumidity();
  if (!isnan(t)) d["temp"] = serialized(String(t, 1));   // omitted if sensor fails -> Trust Engine sees "missing"
  if (!isnan(h)) d["hum"] = serialized(String(h, 1));

  int rr = readAvg(PIN_RAIN);
  float rainWet = constrain(100.0f * (RAIN_RAW_DRY - rr) / (float)(RAIN_RAW_DRY - RAIN_RAW_WET), 0.0f, 100.0f);
  d["rain"] = rainWet > 20 ? 1.0 : 0.0;   // simple wet/dry indicator; use a tipping bucket for mm

  noInterrupts(); uint32_t p = flowPulses; flowPulses = 0; interrupts();
  d["flow"] = serialized(String(p / FLOW_PULSES_PER_L, 3));   // litres since last message

  if (inaGenOk) {
    float genW = inaGen.getPower_mW() / 1000.0f;
    d["gen_w"] = serialized(String(max(0.0f, genW), 1));
    float v = inaGen.getBusVoltage_V();     // battery terminal voltage (measure at rest for SoC)
    d["batt_v"] = serialized(String(v, 2));
    d["batt_soc"] = serialized(String(battSoc(v), 1));
  }
  if (inaLoadOk) d["load_w"] = serialized(String(inaLoad.getPower_mW() / 1000.0f, 1));

  String out; serializeJson(d, out);
  return out;
}

void setup() {
  Serial.begin(115200);
  analogReadResolution(12);
  pinMode(PIN_FLOW, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(PIN_FLOW), onFlow, FALLING);
  dht.begin();
  inaGenOk = inaGen.begin();
  inaLoadOk = inaLoad.begin();
  connectWifi();
  configTime(0, 0, "pool.ntp.org");
  mqtt.setServer(MQTT_HOST, MQTT_PORT);
  mqtt.setBufferSize(512);
}

void loop() {
  static uint32_t last = 0;
  connectWifi();
  if (connectMqtt()) { mqtt.loop(); flushBuffer(); }

  if (millis() - last >= PUBLISH_MS) {
    last = millis();
    String msg = buildMessage();
    Serial.println(msg);
    if (!(mqtt.connected() && mqtt.publish(topic.c_str(), msg.c_str()))) bufPush(msg);
  }
  delay(20);
}
