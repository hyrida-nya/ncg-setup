# NCG Setup

Master's Butler Setup Script for NCG.

## Usage

### Install
To install NCG from scratch:

```bash
chmod +x setup.sh
./setup.sh install
cd ncg
./node_modules/.bin/pm2 start ecosystem.config.js
```

### Update
To pull the latest changes and update dependencies:

```bash
chmod +x setup.sh
./setup.sh update
cd ncg
./node_modules/.bin/pm2 restart ecosystem.config.js
```
