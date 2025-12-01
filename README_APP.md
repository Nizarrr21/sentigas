# SentiGas Monitor 🔥

Aplikasi Flutter untuk monitoring Gas LPG & Suhu secara real-time menggunakan protokol MQTT.

## 📱 Fitur Aplikasi

- **Monitoring Real-time**: Menampilkan data gas LPG (PPM) dan suhu (°C) secara langsung
- **Status Indikator**: Menampilkan status sistem (AMAN, WASPADA, PANAS, BAHAYA)
- **Grafik Live**: Visualisasi data sensor dalam bentuk grafik real-time
- **Auto-Reconnect**: Otomatis reconnect jika koneksi MQTT terputus
- **Responsive UI**: Tampilan modern dengan animasi dan gradient

## 🎨 Tampilan

Aplikasi menampilkan:
- Status sistem dengan warna berbeda berdasarkan kondisi
- Card sensor untuk Gas LPG dan Suhu
- Grafik real-time untuk monitoring trend data
- Indikator koneksi MQTT (Online/Offline)

## 🔧 Teknologi

- **Flutter** - Framework UI
- **MQTT** - Protokol komunikasi IoT
- **FL Chart** - Library untuk grafik
- **Google Fonts** - Typography

## 🚀 Cara Menjalankan

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Jalankan Aplikasi**
   ```bash
   flutter run
   ```

## 📡 Konfigurasi MQTT

Aplikasi terhubung ke broker MQTT publik:
- **Broker**: `broker.emqx.io`
- **Port**: `1883`
- **Topics**:
  - Gas LPG: `project_pantau/sensor/lpg`
  - Suhu: `project_pantau/sensor/suhu`
  - Status: `project_pantau/status/bahaya`

## 🔌 Hardware ESP32

Aplikasi ini dirancang untuk bekerja dengan ESP32 yang memiliki:
- **Sensor MQ-6** (Gas LPG) di GPIO 34
- **DHT22** (Suhu & Kelembaban) di GPIO 4
- **Kipas** (PWM Control) di GPIO 26

### Status Sistem

| Status | Kondisi | Aksi Kipas |
|--------|---------|------------|
| AMAN | Gas < 200 PPM & Suhu normal | Speed rendah (80) |
| WASPADA | Gas 200-500 PPM | Speed sedang (180) |
| PANAS | Suhu > 35°C | Speed tinggi (200) |
| BAHAYA | Gas > 500 PPM | Speed maksimal (255) |

## 📝 Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── models/
│   └── sensor_data.dart      # Model data sensor
├── screens/
│   └── home_screen.dart      # Halaman utama
├── services/
│   └── mqtt_service.dart     # Service MQTT
└── widgets/
    ├── chart_widget.dart     # Widget grafik
    ├── sensor_card.dart      # Widget card sensor
    └── status_indicator.dart # Widget status
```

## 🎯 Cara Kerja

1. Aplikasi terhubung ke broker MQTT `broker.emqx.io`
2. Subscribe ke 3 topik (gas, suhu, status)
3. Menerima data dari ESP32 setiap 2 detik
4. Menampilkan data real-time di UI
5. Menyimpan 20 data terakhir untuk grafik
6. Auto-refresh dengan pull-to-refresh

## 🛠️ Troubleshooting

### Tidak Bisa Koneksi MQTT
- Pastikan koneksi internet aktif
- Cek apakah broker `broker.emqx.io` dapat diakses
- Pastikan tidak ada firewall yang memblokir port 1883

### Data Tidak Muncul
- Pastikan ESP32 sudah running dan terhubung ke WiFi
- Cek apakah ESP32 publish ke topik yang benar
- Lihat log di terminal untuk debug

### Grafik Tidak Update
- Pull-to-refresh untuk reconnect
- Restart aplikasi
- Cek status koneksi di AppBar (Online/Offline)

## 📄 Lisensi

Project ini dibuat untuk keperluan edukasi dan monitoring keamanan gas LPG.

## 👨‍💻 Developer

Dikembangkan dengan ❤️ menggunakan Flutter

---

**⚠️ Catatan Keamanan**: 
- Gunakan sensor gas yang terkalibrasi dengan baik
- Letakkan sensor di lokasi yang tepat
- Sistem ini sebagai monitoring tambahan, bukan pengganti sistem keamanan utama
