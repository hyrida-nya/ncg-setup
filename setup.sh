#!/bin/bash
# NCG Chat Setup Script

echo "--- Installing dependencies ---"
npm install

echo "--- Initializing database ---"
node init-db.js

echo "--- Setup complete! ---"
echo "To start your chat server, run: node server.js"
