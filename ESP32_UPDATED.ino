/*
  UPDATED: Sistem Monitoring Gas LPG & Suhu via MQTT + Fan Control
  Broker: broker.emqx.io (Gratis & Publik)
  
  UPGRADE FEATURES:
  - Manual Fan Control via MQTT
  - Publish Fan Speed Status
  - Publish Humidity Data
  - Mode Control (Auto/Manual)
  
  Hardware Pinout:
  - MQ-6: GPIO 34
  - Fan:  GPIO 26
  - DHT:  GPIO 4
*/

#include <Arduino.h>
#include <DHT.h>
#include <WiFi.h>
#include <PubSubClient.h>

// --- 1. KONFIGURASI WIFI & MQTT ---
const char* ssid = "Wifi Rumah 17A";       // <--- GANTI INI
const char* password = "november1"; // <--- GANTI INI

const char* mqtt_server = "broker.emqx.io";
const int mqtt_port = 1883;

// Topik MQTT (Subscribe & Publish)
const char* topic_gas = "project_pantau/sensor/lpg";
const char* topic_temp = "project_pantau/sensor/suhu";
const char* topic_alert = "project_pantau/status/bahaya";
const char* topic_fan_speed = "project_pantau/sensor/fan_speed";      // NEW: Publish fan speed
const char* topic_fan_control = "project_pantau/control/fan";         // NEW: Subscribe for manual control
const char* topic_mode = "project_pantau/control/mode";               // NEW: Subscribe for mode (AUTO/MANUAL)
const char* topic_humidity = "project_pantau/sensor/humidity";        // NEW: Publish humidity

// --- 2. KONFIGURASI HARDWARE ---
const int pinMQ = 34;      
const int pinFan = 26;     
#define DHTPIN 4       
#define DHTTYPE DHT22  

DHT dht(DHTPIN, DHTTYPE);
WiFiClient espClient;
PubSubClient client(espClient);

// PWM Configuration
const int freq = 5000;
const int resolution = 8;

// Calibration
const float RL = 10.0;     
const float R0 = 2.6;      
const float m = -0.42;
const float b = 2.3;

// Control Variables
bool manualMode = false;       // NEW: Mode control (false = Auto, true = Manual)
int manualFanSpeed = 0;        // NEW: Manual fan speed (0-255)
int currentFanSpeed = 0;       // Current fan speed

// Timer
unsigned long lastMsg = 0;
const long interval = 2000;

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Menghubungkan ke WiFi: ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi Terhubung!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
}

// NEW: MQTT Callback untuk menerima perintah dari aplikasi
void callback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  Serial.print("Pesan dari topik [");
  Serial.print(topic);
  Serial.print("]: ");
  Serial.println(message);
  
  // Control Fan Speed (Manual Mode)
  if (String(topic) == topic_fan_control) {
    manualFanSpeed = message.toInt();
    Serial.print("Manual Fan Speed set to: ");
    Serial.println(manualFanSpeed);
  }
  
  // Control Mode (AUTO/MANUAL)
  if (String(topic) == topic_mode) {
    if (message == "MANUAL") {
      manualMode = true;
      Serial.println("Mode: MANUAL");
    } else {
      manualMode = false;
      Serial.println("Mode: AUTO");
    }
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Menghubungkan ke MQTT...");
    String clientId = "ESP32Client-";
    clientId += String(random(0xffff), HEX);
    
    if (client.connect(clientId.c_str())) {
      Serial.println("BERHASIL KONEK BROKER!");
      
      // Subscribe to control topics
      client.subscribe(topic_fan_control);
      client.subscribe(topic_mode);
      Serial.println("Subscribed to control topics");
      
    } else {
      Serial.print("Gagal, rc=");
      Serial.print(client.state());
      Serial.println(" coba lagi dalam 5 detik");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(pinMQ, INPUT);
  dht.begin();
  
  // Setup PWM
  if (!ledcAttach(pinFan, freq, resolution)) {
    Serial.println("PWM Error");
  }

  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);  // NEW: Set callback untuk terima perintah
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // --- BACA DATA SENSOR ---
  float t = dht.readTemperature();
  float h = dht.readHumidity();
  
  if (isnan(t)) t = 0;
  if (isnan(h)) h = 0;

  // Read Gas Sensor
  float totalADC = 0;
  for(int i = 0; i < 20; i++) {
    totalADC += analogRead(pinMQ);
    delay(1);
  }
  float adcValue = totalADC / 20.0;
  float voltage = (adcValue / 4095.0) * 3.3;
  
  float ppm = 0;
  if(voltage > 0.1) {
    float Rs = ((5.0 * RL) / voltage) - RL;
    float ratio = Rs / R0;
    ppm = pow(10, ((log10(ratio) - b) / m));
  }
  if(ppm < 0) ppm = 0;

  // --- LOGIKA KIPAS ---
  int fanSpeed = 0;
  String status = "AMAN";

  if (manualMode) {
    // MANUAL MODE: Gunakan speed dari aplikasi
    fanSpeed = manualFanSpeed;
    status = "MANUAL";
  } else {
    // AUTO MODE: Logika otomatis
    if (ppm > 500) {
      status = "BAHAYA";
      fanSpeed = 255; 
    } else if (ppm > 200) {
      status = "WASPADA";
      fanSpeed = 180;
    } else if (t > 35.0) {
      status = "PANAS";
      fanSpeed = 200;
    } else {
      status = "AMAN";
      fanSpeed = 80; 
    }
  }
  
  // Set fan speed
  currentFanSpeed = fanSpeed;
  ledcWrite(pinFan, fanSpeed);

  // --- KIRIM DATA KE MQTT (Tiap 2 Detik) ---
  unsigned long now = millis();
  if (now - lastMsg > interval) {
    lastMsg = now;
    
    // Convert to String
    char ppmStr[8];
    dtostrf(ppm, 1, 2, ppmStr);
    
    char tempStr[8];
    dtostrf(t, 1, 2, tempStr);
    
    char humStr[8];
    dtostrf(h, 1, 2, humStr);
    
    char fanStr[8];
    sprintf(fanStr, "%d", currentFanSpeed);
    
    // Publish semua data
    client.publish(topic_gas, ppmStr);
    client.publish(topic_temp, tempStr);
    client.publish(topic_humidity, humStr);           // NEW: Publish humidity
    client.publish(topic_fan_speed, fanStr);          // NEW: Publish fan speed
    client.publish(topic_alert, status.c_str());
    
    Serial.print("Sent MQTT -> Gas: ");
    Serial.print(ppmStr);
    Serial.print(" | Temp: ");
    Serial.print(tempStr);
    Serial.print(" | Humidity: ");
    Serial.print(humStr);
    Serial.print(" | Fan: ");
    Serial.print(fanStr);
    Serial.print(" | Mode: ");
    Serial.println(manualMode ? "MANUAL" : "AUTO");
  }
}
