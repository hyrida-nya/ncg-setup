#!/usr/bin/env bash
# NCG Chat - Master's Butler Setup Script
# Automatically clones NCG and sets up environment in the current directory.

set -euo pipefail

# Check and install git and build tools if missing
if ! command -v git &> /dev/null || ! command -v g++ &> /dev/null; then
    echo "🐾 Git or build tools not found. Attempting to install..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y git build-essential
    elif command -v yum &> /dev/null; then
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y git
    else
        echo "❌ Build tools not found and could not automatically install."
        exit 1
    fi
fi

# Clone repository if it doesn't exist
if [ ! -d "ncg" ]; then
    echo "🐾 Cloning NCG repository (shallow) to ./ncg..."
    git clone --depth 1 https://github.com/hyrida-nya/ncg.git ncg
else
    echo "ℹ️ ./ncg already exists. Skipping clone."
fi

# Switch to the project directory
cd ncg

echo "🐾 Starting NCG Chat setup in $(pwd)..."

# 1. Dependency Check - Force Node v20 LTS (more compatible with older systems)
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo "🐾 Node.js or npm not found. Installing Node.js (v20) via NodeSource..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "✅ Node.js v20 and npm installed."
fi

# 2. Install Dependencies
echo "🐾 Installing dependencies and PM2 locally..."
npm install
npm install pm2

# Force fresh build of sqlite3 from source to fix GLIBC error
echo "🐾 Rebuilding sqlite3 from source..."
rm -rf node_modules/sqlite3
npm install sqlite3 --build-from-source

echo "✅ Dependencies, PM2, and sqlite3 installed."

# 3. Environment Config
if [ ! -f .env ]; then
    echo "🐾 Creating .env file..."
    cat << EOF > .env
PORT=3000
DB_PATH=chat.db
EOF
    echo "✅ Created .env file."
fi

# 4. Create PM2 Ecosystem Config
echo "🐾 Creating ecosystem.config.js for PM2..."
cat << EOF > ecosystem.config.js
module.exports = {
  apps: [{
    name: "ncg-chat",
    script: "server.js",
    instances: "max",
    env: {
      NODE_ENV: "production",
    }
  }]
}
EOF

# 5. Initialize Database
if [ -f "init-db.js" ]; then
    echo "🐾 Initializing database..."
    node init-db.js
else
    echo "❌ init-db.js not found. Skipping database init."
fi

# 6. Verification
echo "🐾 Setup purr-fect! You are ready to start the server."
echo "🐾 Run with: ./node_modules/.bin/pm2 start ecosystem.config.js"
