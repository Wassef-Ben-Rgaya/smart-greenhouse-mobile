# 📱 Smart Greenhouse — Mobile App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)

Part of the [🌿 Smart Greenhouse System](https://github.com/Wassef-Ben-Rgaya/smart-greenhouse)

</div>

---

## 📖 Description

Flutter mobile application for the Smart Greenhouse System. Provides real-time monitoring, remote actuator control, KPI visualization, plant management, and AI-powered growth predictions.

---

## ✨ Features

- 📊 **Real-time KPI Dashboard** — Temperature, humidity, light, soil moisture
- 📈 **Historical Data** — Charts and graphs with custom date ranges
- 🎛️ **Manual Control** — Remote control of pump, lights, fans, heater
- 🔔 **Smart Alerts** — Push notifications on threshold breaches
- 🌱 **Plant Management** — Profiles for Spinach, Romaine Lettuce, Radish
- 📡 **Grafana Integration** — Embedded advanced dashboards
- 👤 **User Management** — Admin and user roles
- 🤖 **AI Predictions** — Plant growth stage forecasting

---

## 🚀 Installation

### Prerequisites
- Flutter SDK >= 3.0
- Dart >= 3.0
- Android Studio / VS Code
- Android or iOS device / emulator

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/Wassef-Ben-Rgaya/smart-greenhouse-mobile.git
cd smart-greenhouse-mobile

# 2. Install dependencies
flutter pub get

# 3. Configure environment
cp lib/config/env.example.dart lib/config/env.dart
# Edit env.dart with your API URL and Firebase config

# 4. Run the app
flutter run
```

---

## 📱 App Screens

| Screen | Description |
|--------|-------------|
| Login / Register | JWT authentication |
| KPI Dashboard | Real-time sensor readings |
| Historical Data | Charts with date filter |
| Manual Control | Actuator on/off toggle |
| Grafana View | Embedded dashboards |
| Plant Profiles | Manage crops & thresholds |
| Alerts | View & configure notifications |
| Profile | User settings & preferences |
| Admin Panel | User & system management |

---

## 🔗 Related Repositories

| Repo | Description |
|------|-------------|
| [smart-greenhouse-backend](https://github.com/Wassef-Ben-Rgaya/smart-greenhouse-backend) | Node.js REST API |
| [smart-greenhouse-plant-prediction](https://github.com/Wassef-Ben-Rgaya/smart-greenhouse-plant-prediction) | AI/ML models & Flask API |
| [smart-greenhouse-iot](https://github.com/Wassef-Ben-Rgaya/smart-greenhouse-iot) | Raspberry Pi IoT scripts |

---

## 👨‍💻 Author

**Wassef BEN RGAYA** — [LinkedIn](https://www.linkedin.com/in/wassef-ben-rgaya-600817188) · [GitHub](https://github.com/Wassef-Ben-Rgaya)

© 2025 — Polytech Tunis Final Year Project
