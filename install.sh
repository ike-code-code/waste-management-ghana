#!/bin/bash

# =============================================
# WASTE MANAGEMENT SYSTEM - AUTO INSTALLER
# One-Click Installation Script
# =============================================

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   WASTE MANAGEMENT SYSTEM - AUTO INSTALLER          ║"
echo "║   Atwima Kwanwoma District Assembly                  ║"
echo "║   🟥 🟨 🟩 ⬛                                        ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${YELLOW}Warning: Running as root. Consider using a non-root user.${NC}"
fi

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
else
    echo -e "${RED}Unsupported OS. This script supports Linux and macOS only.${NC}"
    exit 1
fi

echo "Detected OS: $OS"
echo ""

# =============================================
# STEP 1: Install Dependencies
# =============================================

echo "Step 1: Installing dependencies..."

if [ "$OS" == "linux" ]; then
    # Check if apt is available
    if command -v apt-get &> /dev/null; then
        echo "  → Updating package list..."
        sudo apt-get update -qq
        
        echo "  → Installing PostgreSQL and PostGIS..."
        sudo apt-get install -y postgresql postgresql-contrib postgis > /dev/null 2>&1
        
        echo "  → Installing Node.js..."
        if ! command -v node &> /dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - > /dev/null 2>&1
            sudo apt-get install -y nodejs > /dev/null 2>&1
        fi
    else
        echo -e "${RED}apt-get not found. Please install PostgreSQL and Node.js manually.${NC}"
        exit 1
    fi
elif [ "$OS" == "mac" ]; then
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}Homebrew not found. Please install it first: https://brew.sh${NC}"
        exit 1
    fi
    
    echo "  → Installing PostgreSQL and PostGIS..."
    brew install postgresql postgis > /dev/null 2>&1
    brew services start postgresql > /dev/null 2>&1
    
    echo "  → Installing Node.js..."
    if ! command -v node &> /dev/null; then
        brew install node > /dev/null 2>&1
    fi
fi

echo -e "${GREEN}✓${NC} Dependencies installed"
echo ""

# =============================================
# STEP 2: Database Setup
# =============================================

echo "Step 2: Setting up database..."

# Generate random password
DB_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c16)

# Create database
if [ "$OS" == "linux" ]; then
    sudo -u postgres psql -c "CREATE DATABASE waste_management;" 2>/dev/null
    sudo -u postgres psql -c "CREATE USER waste_admin WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE waste_management TO waste_admin;" 2>/dev/null
    sudo -u postgres psql -d waste_management -c "CREATE EXTENSION postgis;" 2>/dev/null
else
    psql postgres -c "CREATE DATABASE waste_management;" 2>/dev/null
    psql postgres -c "CREATE USER waste_admin WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null
    psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE waste_management TO waste_admin;" 2>/dev/null
    psql waste_management -c "CREATE EXTENSION postgis;" 2>/dev/null
fi

# Load schema
echo "  → Loading database schema..."
PGPASSWORD=$DB_PASSWORD psql -U waste_admin -d waste_management -f database/schema.sql > /dev/null 2>&1

# Load seed data
echo "  → Loading test data..."
PGPASSWORD=$DB_PASSWORD psql -U waste_admin -d waste_management -f database/seed_data.sql > /dev/null 2>&1

echo -e "${GREEN}✓${NC} Database configured"
echo ""

# =============================================
# STEP 3: Backend Setup
# =============================================

echo "Step 3: Setting up backend..."

cd backend

# Install npm packages
echo "  → Installing Node.js packages..."
npm install --silent > /dev/null 2>&1

# Generate JWT secret
JWT_SECRET=$(openssl rand -base64 32)

# Create .env file
cat > .env << EOF
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://waste_admin:$DB_PASSWORD@localhost:5432/waste_management
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=24h
BCRYPT_ROUNDS=12
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
EOF

echo -e "${GREEN}✓${NC} Backend configured"
echo ""

# =============================================
# STEP 4: Start Server
# =============================================

echo "Step 4: Starting server..."

# Start server in background
nohup npm start > ../server.log 2>&1 &
SERVER_PID=$!

# Wait for server to start
sleep 3

# Check if server is running
if kill -0 $SERVER_PID 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Server started on http://localhost:3000"
    echo "  PID: $SERVER_PID"
else
    echo -e "${RED}✗${NC} Server failed to start. Check server.log for details."
    exit 1
fi

cd ..

echo ""

# =============================================
# INSTALLATION COMPLETE
# =============================================

echo "╔═══════════════════════════════════════════════════════╗"
echo "║             INSTALLATION COMPLETE! 🎉                ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Your Waste Management System is ready!${NC}"
echo ""
echo "📊 CREDENTIALS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Database Password: $DB_PASSWORD"
echo "JWT Secret: $JWT_SECRET"
echo ""
echo "Test Accounts:"
echo "  Admin    → Phone: +233200000000, Password: Admin@123"
echo "  Client   → Phone: +233241234567, Password: Test@123"
echo "  Collector→ Phone: +233241111111, Password: Collector@123"
echo ""
echo "📡 API ENDPOINTS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Health Check: http://localhost:3000/health"
echo "API Base URL: http://localhost:3000/api"
echo ""
echo "🧪 TEST THE API:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test login:"
echo "  curl -X POST http://localhost:3000/api/auth/login \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"phone_number\":\"+233200000000\",\"password\":\"Admin@123\"}'"
echo ""
echo "📝 IMPORTANT FILES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  backend/.env       → Environment variables"
echo "  server.log         → Server logs"
echo "  README.md          → Full documentation"
echo "  QUICKSTART.md      → Quick start guide"
echo ""
echo "🛑 TO STOP SERVER:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  kill $SERVER_PID"
echo ""
echo "🚀 NEXT STEPS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Test the API endpoints"
echo "2. Build the mobile app (see mobile/README.md)"
echo "3. Deploy to production (see docs/DEPLOYMENT.md)"
echo ""
echo "🇬🇭 Ghana Waste Management System - Ready to serve!"
echo "🟥 🟨 🟩 ⬛"
echo ""

# Save credentials to file
cat > CREDENTIALS.txt << EOF
WASTE MANAGEMENT SYSTEM - CREDENTIALS
Generated: $(date)

DATABASE:
  Database: waste_management
  Username: waste_admin
  Password: $DB_PASSWORD
  Connection: postgresql://waste_admin:$DB_PASSWORD@localhost:5432/waste_management

JWT:
  Secret: $JWT_SECRET
  Expiry: 24h

TEST ACCOUNTS:
  Admin:     +233200000000 / Admin@123
  Client:    +233241234567 / Test@123
  Collector: +233241111111 / Collector@123

SERVER:
  URL: http://localhost:3000
  PID: $SERVER_PID
  Log: server.log

IMPORTANT: Keep this file secure and delete it after copying credentials to a safe place.
EOF

echo "Credentials saved to: CREDENTIALS.txt"
echo ""
