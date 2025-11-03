#!/bin/bash

# Gold Scalping Bot - Automatic Installation Script
# This will copy files to your MT5 installation

echo "========================================="
echo "  Gold Scalping Bot - Auto Installer"
echo "========================================="
echo ""
echo "This script will help you install the bot to MT5"
echo ""

# Ask user for MT5 Data Folder path
echo "STEP 1: Find your MT5 Data Folder path"
echo "---------------------------------------"
echo "In MT5: Go to File → Open Data Folder"
echo "Copy the full path shown in the window"
echo ""
read -p "Paste your MT5 Data Folder path here: " MT5_PATH

# Remove trailing slash if present
MT5_PATH="${MT5_PATH%/}"

# Check if path exists
if [ ! -d "$MT5_PATH" ]; then
    echo ""
    echo "❌ ERROR: Path not found: $MT5_PATH"
    echo ""
    echo "Please check the path and try again."
    echo "Example path format:"
    echo "  /Users/yourname/Library/Application Support/MetaTrader 5/..."
    exit 1
fi

echo ""
echo "✓ Found MT5 folder: $MT5_PATH"
echo ""

# Check for MQL5 folder
if [ ! -d "$MT5_PATH/MQL5" ]; then
    echo "❌ ERROR: MQL5 folder not found in: $MT5_PATH"
    echo ""
    echo "Make sure you copied the full path to the MT5 Data Folder"
    exit 1
fi

echo "✓ Found MQL5 folder"
echo ""

# Create Experts and Include folders if they don't exist
mkdir -p "$MT5_PATH/MQL5/Experts"
mkdir -p "$MT5_PATH/MQL5/Include"

echo "STEP 2: Copying files..."
echo "---------------------------------------"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Copy EA to Experts
if [ -f "$SCRIPT_DIR/FOR_EXPERTS_FOLDER/GoldScalpingBot.mq5" ]; then
    cp "$SCRIPT_DIR/FOR_EXPERTS_FOLDER/GoldScalpingBot.mq5" "$MT5_PATH/MQL5/Experts/"
    echo "✓ Copied GoldScalpingBot.mq5 → Experts/"
else
    echo "❌ ERROR: GoldScalpingBot.mq5 not found"
    exit 1
fi

# Copy library to Include
if [ -f "$SCRIPT_DIR/FOR_INCLUDE_FOLDER/SST_ScalpingStrategy.mqh" ]; then
    cp "$SCRIPT_DIR/FOR_INCLUDE_FOLDER/SST_ScalpingStrategy.mqh" "$MT5_PATH/MQL5/Include/"
    echo "✓ Copied SST_ScalpingStrategy.mqh → Include/"
else
    echo "❌ ERROR: SST_ScalpingStrategy.mqh not found"
    exit 1
fi

echo ""
echo "========================================="
echo "  ✅ Installation Complete!"
echo "========================================="
echo ""
echo "Files installed to:"
echo "  $MT5_PATH/MQL5/Experts/GoldScalpingBot.mq5"
echo "  $MT5_PATH/MQL5/Include/SST_ScalpingStrategy.mqh"
echo ""
echo "NEXT STEPS:"
echo "1. Open MetaEditor in MT5 (press F4)"
echo "2. Find GoldScalpingBot.mq5 in Experts folder"
echo "3. Press F7 to compile"
echo "4. You should see: '0 error(s), 0 warning(s)'"
echo ""
echo "Good luck! 🚀"
echo ""
