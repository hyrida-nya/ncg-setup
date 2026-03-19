#!/usr/bin/env bash
# NCG Chat - Master's Butler Setup Script
# Usage: ./setup.sh [install|update]

set -euo pipefail

function check_tools() {
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
}

function install_node_pm2() {
    if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
        echo "🐾 Node.js or npm not found. Installing Node.js (v20) via NodeSource..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
}

function rebuild_sqlite3() {
    echo "🐾 Rebuilding sqlite3 from source..."
    rm -rf node_modules/sqlite3
    npm install sqlite3 --build-from-source
}

function run_install() {
    check_tools
    
    if [ ! -d "ncg" ]; then
        echo "🐾 Cloning NCG repository..."
        git clone --depth 1 https://github.com/hyrida-nya/ncg.git ncg
    else
        echo "⚠️ ./ncg already exists. Aborting install to prevent overwrite."
        exit 1
    fi

    cd ncg
    install_node_pm2
    
    echo "🐾 Installing dependencies and forcing latest PM2..."
    npm install
    npm install pm2@latest --save

    echo "🐾 Running audit fix..."
    npm audit fix --audit-level=high || echo "⚠️ Audit fix encountered some issues."
    
    rebuild_sqlite3

    if [ ! -f .env ]; then
        echo "🐾 Creating .env..."
        cat << EOF > .env
PORT=3000
DB_PATH=chat.db
EOF
    fi

    if [ ! -f ecosystem.config.js ]; then
        echo "🐾 Creating ecosystem.config.js..."
        cat << EOF > ecosystem.config.js
module.exports = {
  apps: [{
    name: "ncg-chat",
    script: "server.js",
    instances: "max",
    env: { NODE_ENV: "production" }
  }]
}
EOF
    fi

    if [ -f "init-db.js" ]; then
        echo "🐾 Initializing database..."
        node init-db.js
    fi
    
    echo "✅ Install complete!"
    echo "🐾 To start the server, run: cd ncg && ./node_modules/.bin/pm2 start ecosystem.config.js"
}

function run_update() {
    if [ ! -d "ncg" ]; then
        echo "❌ ./ncg directory not found. Run 'install' first!"
        exit 1
    fi

    cd ncg
    echo "🐾 Pulling latest changes..."
    git pull

    echo "🐾 Updating dependencies and PM2..."
    npm install
    npm install pm2@latest --save
    
    echo "🐾 Running audit fix..."
    npm audit fix --audit-level=high || echo "⚠️ Audit fix encountered some issues."

    # Only rebuild if the directory is missing, implying it hasn't been built yet
    if [ ! -d "node_modules/sqlite3" ]; then
        rebuild_sqlite3
    else
        echo "✅ sqlite3 already exists. Skipping rebuild."
    fi

    echo "✅ Update complete!"
    echo "🐾 To restart the server, run: cd ncg && ./node_modules/.bin/pm2 restart ecosystem.config.js"
}

# Argument parsing
if [ $# -eq 0 ]; then
    echo "Usage: ./setup.sh [install|update]"
    exit 1
fi

case "$1" in
    install)
        run_install
        ;;
    update)
        run_update
        ;;
    *)
        echo "Invalid argument: $1"
        echo "Usage: ./setup.sh [install|update]"
        exit 1
        ;;
esac
