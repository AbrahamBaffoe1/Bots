#!/bin/bash

# MT5 Trading System Setup Script
# This script helps you set up the MT5 trading system quickly

set -e  # Exit on error

echo "========================================="
echo "  MT5 Trading System Setup"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Python is installed
echo "Checking dependencies..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python 3 is not installed!${NC}"
    echo "Please install Python 3.9-3.11 from https://www.python.org"
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

echo -e "${GREEN}✓ Python $PYTHON_VERSION found${NC}"

# Warn if Python version may not be compatible with MetaTrader5
if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -gt 11 ]; then
    echo -e "${YELLOW}⚠ WARNING: Python $PYTHON_VERSION detected${NC}"
    echo -e "${YELLOW}⚠ MetaTrader5 package supports Python 3.8-3.11${NC}"
    echo ""
    echo "Options to fix this:"
    echo "1. Install Python 3.11 and use it for this project"
    echo "2. Continue anyway (MT5 bridge may not work on macOS)"
    echo ""
    read -p "Continue with Python $PYTHON_VERSION? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "To install Python 3.11:"
        echo "  macOS (Homebrew): brew install python@3.11"
        echo "  Or download from: https://www.python.org/downloads/"
        echo ""
        echo "Then create venv with:"
        echo "  python3.11 -m venv venv"
        echo "  source venv/bin/activate"
        echo "  pip install -r requirements.txt"
        exit 1
    fi
    echo -e "${YELLOW}⚠ Continuing with Python $PYTHON_VERSION...${NC}"
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}✗ pip3 is not installed!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ pip3 found${NC}"

# Create virtual environment
echo ""
echo "Creating virtual environment..."
if [ -d "venv" ]; then
    echo -e "${YELLOW}Virtual environment already exists, skipping...${NC}"
else
    python3 -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate
echo -e "${GREEN}✓ Virtual environment activated${NC}"

# Install requirements
echo ""
echo "Installing Python dependencies..."
pip install --upgrade pip

# Special handling for MetaTrader5 on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${YELLOW}⚠ macOS detected: MetaTrader5 package may not work${NC}"
    echo -e "${YELLOW}⚠ MT5 requires Windows or Wine/VM on macOS${NC}"
    echo ""
    echo "Installing other dependencies (excluding MetaTrader5)..."
    # Install without MetaTrader5
    pip install websockets asyncio python-dotenv requests aiohttp numpy colorlog
    echo -e "${YELLOW}✓ Dependencies installed (MT5 package skipped on macOS)${NC}"
    echo ""
    echo -e "${YELLOW}Note: To use MT5 bridge on macOS, you need:${NC}"
    echo "  1. MT5 running in Wine/Windows VM"
    echo "  2. Python with MetaTrader5 in that environment"
    echo "  OR use a Windows VPS for the bridge"
else
    # On Windows, install normally
    pip install -r requirements.txt
    echo -e "${GREEN}✓ Dependencies installed${NC}"
fi

# Create .env file if it doesn't exist
echo ""
if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠ .env file already exists, skipping...${NC}"
else
    echo "Creating .env file..."
    cp .env.example .env
    echo -e "${GREEN}✓ .env file created${NC}"
    echo -e "${YELLOW}⚠ Please edit .env file with your MT5 credentials!${NC}"
fi

# Create logs directory
echo ""
echo "Creating logs directory..."
mkdir -p logs
echo -e "${GREEN}✓ Logs directory created${NC}"

# Check if backend exists and node modules are installed
echo ""
if [ -d "../backend" ]; then
    echo "Checking backend setup..."
    cd ../backend

    if [ ! -d "node_modules" ]; then
        echo "Installing backend dependencies..."
        npm install
        echo -e "${GREEN}✓ Backend dependencies installed${NC}"
    else
        echo -e "${GREEN}✓ Backend dependencies already installed${NC}"
    fi

    cd ../NewBot
else
    echo -e "${YELLOW}⚠ Backend directory not found${NC}"
    echo "Make sure you have the backend folder in the parent directory"
fi

# Summary
echo ""
echo "========================================="
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Edit .env file with your MT5 credentials"
echo "2. Start the backend:  cd ../backend && npm start"
echo "3. Start the bridge:   source venv/bin/activate && python mt5_bridge.py"
echo "4. Open MT5 and attach EAs to charts"
echo ""
echo "For detailed instructions, see README.md and QUICKSTART.md"
echo ""
echo -e "${YELLOW}IMPORTANT: Always test on DEMO account first!${NC}"
echo ""
