# 🗑️ Waste Management System

**Atwima Kwanwoma District Assembly**  
**Ghana Flag Colors:** 🟥 Red | 🟨 Gold | 🟩 Green | ⬛ Black

Complete mobile-first waste collection system for household solid waste management in Ghana.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [API Documentation](#api-documentation)
- [Mobile App](#mobile-app)
- [Deployment](#deployment)
- [Testing](#testing)
- [Contributing](#contributing)

---

## 🎯 Overview

This system digitizes waste collection operations including:
- ✅ Household registration with GPS
- ✅ Automated collection scheduling
- ✅ Real-time GPS tracking of collectors
- ✅ Dynamic billing based on waste weight, type, and distance
- ✅ Mobile Money payments (MTN, Vodafone, AirtelTigo)
- ✅ Offline-first mobile apps
- ✅ Administrative dashboards
- ✅ AI route optimization

---

## ✨ Features

### For Clients (Households)
- Self-registration via mobile app
- Schedule viewing and notifications
- Multiple waste types (Domestic, Plastics, Papers)
- Multiple bin types (240L, 1100L, Waste Bags)
- One-time or recurring pickups
- Bill viewing and Mobile Money payments
- Collection confirmation

### For Waste Collectors
- Daily task list with GPS navigation
- Offline report submission
- Automatic GPS and timestamp capture
- Weight recording (manual or scale)
- Performance metrics

### For Administrators
- Dashboard with real-time stats
- User management
- Schedule creation and optimization
- Pricing configuration
- Revenue and waste reports
- Route optimization AI

---

## 🛠️ Tech Stack

### Backend
- **Runtime:** Node.js 18+
- **Framework:** Express.js
- **Database:** PostgreSQL 14+ with PostGIS
- **Authentication:** JWT (JSON Web Tokens)
- **Password Hashing:** bcrypt
- **Payments:** Hubtel API (Mobile Money)

### Mobile App
- **Framework:** Flutter 3.x
- **State Management:** Provider
- **Local Database:** Sqflite
- **Maps:** Google Maps Flutter
- **HTTP:** Dio

### Admin Dashboard
- **Framework:** React / Vue.js (TBD)
- **Charts:** Recharts
- **Maps:** Leaflet / Google Maps

---

## 📁 Project Structure

```
waste-management-system/
├── backend/                 # Node.js API
│   ├── config/             # Database and app config
│   ├── routes/             # API route handlers
│   ├── controllers/        # Business logic
│   ├── middleware/         # Auth, validation, etc.
│   ├── utils/              # Helper functions
│   ├── models/             # Data models
│   ├── server.js           # Entry point
│   └── package.json
│
├── mobile/                  # Flutter app
│   ├── lib/
│   │   ├── models/         # Data models
│   │   ├── services/       # API and local services
│   │   ├── providers/      # State management
│   │   ├── screens/        # UI screens
│   │   ├── widgets/        # Reusable components
│   │   └── utils/          # Helpers and constants
│   ├── pubspec.yaml
│   └── README.md
│
├── admin-dashboard/         # Web admin panel
│   ├── src/
│   ├── public/
│   └── package.json
│
├── database/                # SQL scripts
│   ├── schema.sql          # Complete database schema
│   └── seed_data.sql       # Sample data for testing
│
├── deployment/              # Deployment scripts
│   ├── nginx.conf          # Nginx configuration
│   ├── pm2.config.js       # PM2 process manager
│   └── deploy.sh           # Deployment script
│
└── docs/                    # Documentation
    ├── API.md              # API endpoints
    ├── SETUP.md            # Setup guide
    └── USER_MANUAL.md      # User guides
```

---

## 🚀 Installation

### Prerequisites

- Node.js 18+ and npm
- PostgreSQL 14+ with PostGIS extension
- Flutter SDK 3.0+ (for mobile app)
- Git

### 1. Clone Repository

```bash
git clone <repository-url>
cd waste-management-system
```

### 2. Database Setup

```bash
# Install PostgreSQL and PostGIS
sudo apt install postgresql postgresql-contrib postgis

# Create database and user
sudo -u postgres psql
CREATE DATABASE waste_management;
CREATE USER waste_admin WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE waste_management TO waste_admin;
\c waste_management
CREATE EXTENSION postgis;
\q

# Run schema
psql -U waste_admin -d waste_management -f database/schema.sql

# Load seed data (optional for testing)
psql -U waste_admin -d waste_management -f database/seed_data.sql
```

### 3. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your configuration
nano .env

# Start server
npm start

# Or for development with auto-reload
npm run dev
```

### 4. Mobile App Setup

```bash
cd mobile

# Install Flutter dependencies
flutter pub get

# Run on Android emulator or device
flutter run

# Build APK for release
flutter build apk --release
```

---

## ⚙️ Configuration

### Environment Variables (.env)

```env
# Database
DATABASE_URL=postgresql://waste_admin:password@localhost:5432/waste_management

# JWT
JWT_SECRET=your_super_secret_key_here
JWT_EXPIRES_IN=24h

# Mobile Money (Hubtel)
HUBTEL_CLIENT_ID=your_client_id
HUBTEL_CLIENT_SECRET=your_client_secret
HUBTEL_MERCHANT_ID=your_merchant_id
PAYMENT_CALLBACK_URL=https://yourdomain.com/api/payments/webhook

# Server
PORT=3000
NODE_ENV=development
```

### Mobile App Configuration

Edit `mobile/lib/utils/constants.dart`:

```dart
class AppConfig {
  static const String API_BASE_URL = 'http://your-server-ip:3000/api';
  static const String GOOGLE_MAPS_API_KEY = 'your_google_maps_key';
}
```

---

## 🏃 Running the Application

### Development Mode

**Backend:**
```bash
cd backend
npm run dev
# Server starts on http://localhost:3000
```

**Mobile App:**
```bash
cd mobile
flutter run
# App launches on connected device/emulator
```

### Test Credentials

After running seed data:

| Role | Phone | Password |
|------|-------|----------|
| Admin | +233200000000 | Admin@123 |
| Client | +233241234567 | Test@123 |
| Collector | +233241111111 | Collector@123 |

---

## 📚 API Documentation

### Base URL
```
http://localhost:3000/api
```

### Authentication

All authenticated endpoints require Bearer token:
```
Authorization: Bearer <jwt_token>
```

### Key Endpoints

#### Authentication
```
POST /auth/register     # Register new client
POST /auth/login        # Login (any role)
POST /auth/logout       # Logout
```

#### Clients
```
GET    /clients/profile          # Get client profile
PUT    /clients/profile          # Update profile
GET    /clients/schedule         # Get collection schedule
POST   /clients/request-pickup   # Request pickup
GET    /clients/bills            # Get bills
POST   /clients/confirm-collection  # Confirm collection
```

#### Collectors
```
GET    /collectors/tasks         # Get daily tasks
POST   /collectors/submit-report # Submit collection report
POST   /collectors/sync-offline-reports  # Sync offline reports
GET    /collectors/performance   # Get performance metrics
```

#### Admin
```
GET    /admin/dashboard-stats    # Dashboard statistics
POST   /admin/collectors         # Create collector account
POST   /admin/schedules          # Create schedule
POST   /admin/optimize-route     # Optimize route
GET    /admin/reports            # Generate reports
POST   /admin/pricing-config     # Configure pricing
```

#### Payments
```
POST   /payments/initiate        # Initiate Mobile Money payment
GET    /payments/status/:id      # Check payment status
POST   /payments/webhook         # Payment callback (Hubtel)
```

See [docs/API.md](docs/API.md) for complete API documentation.

---

## 📱 Mobile App

### Features

**Client App:**
- Registration with GPS auto-capture
- View upcoming collections
- Request one-time or recurring pickups
- View and pay bills via Mobile Money
- Confirm/dispute collections

**Collector App:**
- View daily task list
- GPS navigation to locations
- Submit reports offline
- Photo capture for evidence
- Performance dashboard

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# Install on device
flutter install
```

---

## 🌐 Deployment

### DigitalOcean Deployment

1. **Create Droplet**
```bash
# Ubuntu 24.04, 2GB RAM minimum
ssh root@your_server_ip
```

2. **Run Deployment Script**
```bash
cd waste-management-system/deployment
chmod +x deploy.sh
./deploy.sh
```

3. **Configure Domain**
```bash
# Point your domain to server IP
# Update nginx configuration
sudo nano /etc/nginx/sites-available/waste-api
sudo systemctl restart nginx
```

4. **Install SSL**
```bash
sudo certbot --nginx -d yourdomain.com
```

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed deployment guide.

---

## 🧪 Testing

### Backend Tests

```bash
cd backend
npm test
```

### Mobile App Tests

```bash
cd mobile
flutter test
```

---

## 💰 Cost Estimate (Monthly)

| Item | Cost (GHS) |
|------|-----------|
| DigitalOcean Droplet (2GB) | 200 |
| Managed PostgreSQL | 250 |
| Domain | 20 |
| Mobile Money fees (2-3%) | Variable |
| **Total** | **470 + transaction fees** |

---

## 📞 Support

For issues and questions:
- **Email:** admin@wasteghanapp.com
- **Phone:** +233200000000
- **GitHub Issues:** [Link to issues]

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🇬🇭 About

Developed for Atwima Kwanwoma District Assembly  
Supporting environmental health and sustainable waste management in Ghana

**Colors:** 🟥 Red | 🟨 Gold | 🟩 Green | ⬛ Black (Ghana Flag)

---

## 🙏 Acknowledgments

- Atwima Kwanwoma District Assembly
- Ghana Tech Community
- Environmental Health Officers
- Waste Management Companies

---

**Last Updated:** February 2026  
**Version:** 1.0.0
