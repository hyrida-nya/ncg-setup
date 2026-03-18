#!/usr/bin/env bash
# NCG Chat - Master's Butler Setup Script
# Automatically clones NCG and sets up environment in the current directory.

set -euo pipefail

# Check and install git if missing
if ! command -v git &> /dev/null; then
    echo "🐾 Git not found. Attempting to install git..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y git
    elif command -v yum &> /dev/null; then
        sudo yum install -y git
    else
        echo "❌ Git not found and could not automatically install. Please install git manually (e.g., 'sudo apt install git' or 'sudo yum install git')."
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

# 1. Dependency Check
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo "🐾 Node.js or npm not found. Installing Node.js via NodeSource..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "✅ Node.js and npm installed."
fi

# 2. Install Dependencies (including PM2 locally to avoid permission issues)
echo "🐾 Installing dependencies and PM2 locally..."
npm install
npm install pm2

echo "✅ Dependencies and PM2 installed."

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
