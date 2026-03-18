#!/usr/bin/env bash
# NCG Chat - Master's Butler Setup Script
# Automatically clones NCG and sets up environment in the current directory.

set -euo pipefail

# Clone repository if it doesn't exist
if [ ! -d "ncg" ]; then
    echo "🐾 Cloning NCG repository (shallow) to ./ncg..."
    if command -v git &> /dev/null; then
        git clone --depth 1 https://github.com/hyrida-nya/ncg.git ncg
    else
        echo "❌ Git not found. Please install git."
        exit 1
    fi
else
    echo "ℹ️ ./ncg already exists. Skipping clone."
fi

# Switch to the project directory
cd ncg

echo "🐾 Starting NCG Chat setup in $(pwd)..."

# 1. Dependency Check
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo "🐾 Node.js or npm not found. Installing NVM and Node.js..."
    # Install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    # Load NVM (this works in the current shell session)
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install Node.js LTS
    nvm install --lts
    nvm use --lts
    echo "✅ Node.js and npm installed via NVM."
fi

# Ensure PM2 is installed globally
if ! command -v pm2 &> /dev/null; then
    echo "🐾 Installing PM2 globally..."
    npm install -g pm2
fi

echo "✅ Node.js, npm, and PM2 found."

# 2. Install Dependencies
if [ -f "package.json" ]; then
    echo "🐾 Installing dependencies..."
    npm install
else
    echo "❌ package.json not found. Something went wrong with the clone."
    exit 1
fi

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
echo "🐾 Run with: pm2 start ecosystem.config.js"
