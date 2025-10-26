#!/bin/bash

# Quick fix script for Python version issue
# This script installs Python 3.11 and recreates the venv

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "========================================="
echo "  Python Version Fix Script"
echo "========================================="
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}✗ Homebrew not found${NC}"
    echo "Please install Homebrew first:"
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
fi

# Install Python 3.11
echo "Installing Python 3.11..."
brew install python@3.11

# Verify installation
if ! command -v python3.11 &> /dev/null; then
    echo -e "${RED}✗ Python 3.11 installation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Python 3.11 installed${NC}"
python3.11 --version

# Remove old venv
echo ""
echo "Removing old virtual environment..."
if [ -d "venv" ]; then
    rm -rf venv
    echo -e "${GREEN}✓ Old venv removed${NC}"
else
    echo -e "${YELLOW}No old venv found${NC}"
fi

# Create new venv with Python 3.11
echo ""
echo "Creating new virtual environment with Python 3.11..."
python3.11 -m venv venv
echo -e "${GREEN}✓ New venv created${NC}"

# Activate venv
echo ""
echo "Activating virtual environment..."
source venv/bin/activate

# Verify Python version in venv
VENV_PYTHON_VERSION=$(python --version 2>&1)
echo -e "${GREEN}✓ Virtual environment Python: $VENV_PYTHON_VERSION${NC}"

# Upgrade pip
echo ""
echo "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo ""
echo "Installing dependencies..."

# Check if we're on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${YELLOW}⚠ macOS detected - installing without MetaTrader5 package${NC}"
    pip install websockets python-dotenv requests aiohttp numpy colorlog
    echo -e "${GREEN}✓ Dependencies installed (MT5 package excluded)${NC}"
    echo ""
    echo -e "${YELLOW}Note: MetaTrader5 package is Windows-only${NC}"
    echo "Run the MT5 bridge on Windows VPS or use EAs without bridge"
else
    pip install -r requirements.txt
    echo -e "${GREEN}✓ All dependencies installed${NC}"
fi

# Test imports
echo ""
echo "Testing package imports..."
python -c "import websockets; print('✓ websockets')"
python -c "import asyncio; print('✓ asyncio')"
python -c "import dotenv; print('✓ python-dotenv')"
python -c "import requests; print('✓ requests')"

if [[ "$OSTYPE" != "darwin"* ]]; then
    python -c "import MetaTrader5; print('✓ MetaTrader5')" 2>/dev/null || echo -e "${YELLOW}⚠ MetaTrader5 package not available (expected on macOS)${NC}"
fi

echo ""
echo "========================================="
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo "========================================="
echo ""
echo "Python version in venv: $VENV_PYTHON_VERSION"
echo ""
echo "To activate the virtual environment in the future:"
echo "  source venv/bin/activate"
echo ""
echo "To run the MT5 bridge:"
echo "  source venv/bin/activate"
echo "  python mt5_bridge.py"
echo ""

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${YELLOW}macOS Users:${NC}"
    echo "- See MACOS_SETUP.md for deployment options"
    echo "- Run MT5 bridge on Windows VPS for production"
    echo "- Or run EAs without bridge (disable WebSocket)"
    echo ""
fi

echo "For more info, see:"
echo "  - QUICKSTART.md"
echo "  - PYTHON_VERSION_FIX.md"
echo "  - MACOS_SETUP.md (for macOS users)"
echo ""
