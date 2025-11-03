#!/bin/bash

# Gold Scalping Bot - Installation Script for MT5
# This script copies the bot files to your MT5 installation

echo "========================================="
echo "  Gold Scalping Bot - MT5 Installer"
echo "========================================="
echo ""

# Detect MT5 data folder
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "Detected macOS system"
    MT5_BASE="$HOME/Library/Application Support/MetaTrader 5/Bottles"

    if [ ! -d "$MT5_BASE" ]; then
        echo "ERROR: MT5 not found at: $MT5_BASE"
        echo ""
        echo "Please find your MT5 Data Folder manually:"
        echo "1. Open MetaTrader 5"
        echo "2. Go to: File → Open Data Folder"
        echo "3. Navigate to: MQL5/"
        echo "4. Copy files manually:"
        echo "   - GoldScalpingBot.mq5 → MQL5/Experts/"
        echo "   - SST_ScalpingStrategy.mqh → MQL5/Include/"
        exit 1
    fi

    # Find the actual terminal folder
    TERMINAL_DIRS=$(find "$MT5_BASE" -type d -name "Terminal" 2>/dev/null)

    if [ -z "$TERMINAL_DIRS" ]; then
        echo "ERROR: Could not find Terminal folder in MT5"
        echo "Please copy files manually (see instructions above)"
        exit 1
    fi

    # Use the first Terminal folder found
    TERMINAL_DIR=$(echo "$TERMINAL_DIRS" | head -n 1)

    # Find MQL5 folder
    MQL5_DIRS=$(find "$TERMINAL_DIR" -type d -name "MQL5" 2>/dev/null)

    if [ -z "$MQL5_DIRS" ]; then
        echo "ERROR: Could not find MQL5 folder"
        echo "Please copy files manually"
        exit 1
    fi

    MT5_DATA=$(echo "$MQL5_DIRS" | head -n 1)

elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows
    echo "Detected Windows system"
    MT5_DATA="$APPDATA/MetaQuotes/Terminal/*/MQL5"
else
    echo "ERROR: Unsupported operating system: $OSTYPE"
    exit 1
fi

echo "MT5 Data Folder: $MT5_DATA"
echo ""

# Check if MT5 folders exist
if [ ! -d "$MT5_DATA" ]; then
    echo "ERROR: MT5 MQL5 folder not found at: $MT5_DATA"
    echo ""
    echo "MANUAL INSTALLATION REQUIRED:"
    echo "1. Open MetaTrader 5"
    echo "2. Go to: File → Open Data Folder"
    echo "3. Navigate to: MQL5/"
    echo "4. Copy these files:"
    echo "   FROM: $(pwd)/MT5/GoldScalpingBot.mq5"
    echo "   TO:   [MT5 Data]/MQL5/Experts/"
    echo ""
    echo "   FROM: $(pwd)/Include/SST_ScalpingStrategy.mqh"
    echo "   TO:   [MT5 Data]/MQL5/Include/"
    exit 1
fi

# Create directories if they don't exist
mkdir -p "$MT5_DATA/Experts"
mkdir -p "$MT5_DATA/Include"

echo "Installing files..."

# Copy main EA
if [ -f "MT5/GoldScalpingBot.mq5" ]; then
    cp "MT5/GoldScalpingBot.mq5" "$MT5_DATA/Experts/"
    echo "✓ Copied GoldScalpingBot.mq5 to Experts/"
else
    echo "✗ ERROR: GoldScalpingBot.mq5 not found in MT5/ folder"
    exit 1
fi

# Copy strategy library
if [ -f "Include/SST_ScalpingStrategy.mqh" ]; then
    cp "Include/SST_ScalpingStrategy.mqh" "$MT5_DATA/Include/"
    echo "✓ Copied SST_ScalpingStrategy.mqh to Include/"
else
    echo "✗ ERROR: SST_ScalpingStrategy.mqh not found in Include/ folder"
    exit 1
fi

echo ""
echo "========================================="
echo "  Installation Complete! ✓"
echo "========================================="
echo ""
echo "Next Steps:"
echo "1. Open MetaEditor in MT5 (press F4)"
echo "2. Navigate to: Experts/GoldScalpingBot.mq5"
echo "3. Click Compile (F7)"
echo "4. Should see: '0 error(s), 0 warning(s)'"
echo ""
echo "Files installed to:"
echo "$MT5_DATA/Experts/GoldScalpingBot.mq5"
echo "$MT5_DATA/Include/SST_ScalpingStrategy.mqh"
echo ""
