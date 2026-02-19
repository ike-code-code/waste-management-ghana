# 🚀 QUICK START GUIDE
## Waste Management System

### ⏱️ Get Running in 15 Minutes

---

## Step 1: Extract Files (1 minute)

```bash
# Extract the downloaded ZIP file
unzip waste-management-system.zip
cd waste-management-system
```

---

## Step 2: Install PostgreSQL (3 minutes)

### On Ubuntu/Debian:
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib postgis
sudo systemctl start postgresql
```

### On macOS:
```bash
brew install postgresql postgis
brew services start postgresql
```

### On Windows:
Download from: https://www.postgresql.org/download/windows/

---

## Step 3: Create Database (2 minutes)

```bash
# Login to PostgreSQL
sudo -u postgres psql

# Run these commands:
CREATE DATABASE waste_management;
CREATE USER waste_admin WITH PASSWORD 'MySecurePass123';
GRANT ALL PRIVILEGES ON DATABASE waste_management TO waste_admin;
\c waste_management
CREATE EXTENSION postgis;
\q

# Load the schema
psql -U waste_admin -d waste_management -f database/schema.sql

# (Optional) Load test data
psql -U waste_admin -d waste_management -f database/seed_data.sql
```

---

## Step 4: Set Up Backend (3 minutes)

```bash
cd backend

# Install Node.js if needed
# Ubuntu: sudo apt install nodejs npm
# macOS: brew install node
# Windows: Download from https://nodejs.org

# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Edit .env file (use nano, vim, or any text editor)
nano .env

# Update these values:
DATABASE_URL=postgresql://waste_admin:MySecurePass123@localhost:5432/waste_management
JWT_SECRET=change_this_to_random_string_xyz123
PORT=3000

# Save and exit (Ctrl+X, then Y, then Enter)

# Start the server
npm start
```

You should see:
```
╔═══════════════════════════════════════════════════════╗
║   WASTE MANAGEMENT API - SERVER STARTED              ║
║   Port: 3000                                         ║
╚═══════════════════════════════════════════════════════╝
```

---

## Step 5: Test the API (2 minutes)

Open another terminal and test:

```bash
# Health check
curl http://localhost:3000/health

# Should return:
# {"status":"healthy","timestamp":"...","environment":"development"}

# Test login with default admin
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+233200000000",
    "password": "Admin@123"
  }'

# Should return a JWT token!
```

---

## Step 6: Install Mobile App (4 minutes)

### Prerequisites:
- Install Flutter: https://docs.flutter.dev/get-started/install
- Install Android Studio (for emulator)

```bash
cd ../mobile

# Install dependencies
flutter pub get

# Configure API URL
# Edit lib/utils/constants.dart
# Change API_BASE_URL to your computer's IP:
# - If testing on emulator: http://10.0.2.2:3000/api
# - If testing on real device: http://YOUR_COMPUTER_IP:3000/api

# Run the app
flutter run

# Or build APK
flutter build apk --release
# APK location: build/app/outputs/flutter-apk/app-release.apk
```

---

## ✅ Success Checklist

- [ ] PostgreSQL installed and running
- [ ] Database created with schema loaded
- [ ] Backend server running on http://localhost:3000
- [ ] Can successfully login via API
- [ ] Mobile app runs on emulator/device

---

## 🎉 You're Ready!

### Test Accounts (from seed data):

| Role | Phone | Password |
|------|-------|----------|
| **Admin** | +233200000000 | Admin@123 |
| **Client** | +233241234567 | Test@123 |
| **Collector** | +233241111111 | Collector@123 |

---

## 🐛 Troubleshooting

### "Database connection failed"
- Check PostgreSQL is running: `sudo systemctl status postgresql`
- Verify credentials in `.env` file
- Test connection: `psql -U waste_admin -d waste_management`

### "Port 3000 already in use"
- Change PORT in `.env` to 3001 or another port
- Kill existing process: `lsof -ti:3000 | xargs kill`

### "npm install fails"
- Update Node.js: https://nodejs.org
- Clear cache: `npm cache clean --force`
- Delete `node_modules` and retry: `rm -rf node_modules && npm install`

### "Flutter not found"
- Install Flutter: https://docs.flutter.dev/get-started/install
- Add to PATH: `export PATH="$PATH:`pwd`/flutter/bin"`
- Run: `flutter doctor`

### Mobile app can't connect to API
- Check API_BASE_URL in `mobile/lib/utils/constants.dart`
- Use `10.0.2.2` for Android emulator
- Use your computer's IP for real devices
- Ensure backend is running
- Check firewall isn't blocking port 3000

---

## 📚 Next Steps

1. **Read Full Documentation:** See `README.md`
2. **Configure Mobile Money:** Sign up at https://developers.hubtel.com
3. **Customize UI:** Edit Flutter app with Ghana flag colors
4. **Deploy to Production:** See `docs/DEPLOYMENT.md`
5. **Add More Features:** Explore the codebase!

---

## 🆘 Need Help?

- **API Documentation:** `docs/API.md`
- **Database Schema:** `database/schema.sql`
- **Example Requests:** `docs/EXAMPLES.md`

---

## 🎯 What You Have Now

✅ **Working Backend API** with authentication, database, and all endpoints  
✅ **Mobile App** (Flutter) ready to customize  
✅ **Database Schema** with sample data  
✅ **Complete Documentation**  
✅ **Deployment Scripts** for production  

**Time to start customizing and deploying! 🚀**

---

**Ghana Waste Management System**  
🟥 🟨 🟩 ⬛
