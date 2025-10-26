# macOS Setup Guide - MT5 Trading System

## The macOS Challenge

MetaTrader 5 and its Python package (`MetaTrader5`) are **Windows-only**. However, you have several options to use this system on macOS:

## Option 1: Use Windows VPS (Recommended for Trading)

### Why This is Best for Trading
- 24/7 uptime
- Low latency to broker servers
- No need to keep your Mac running
- Professional trading setup

### Setup Steps

1. **Get a Windows VPS** ($15-50/month):
   - [ForexVPS.net](https://www.forexvps.net)
   - [Cheap Windows VPS](https://www.cheapwindowsvps.com)
   - [Vultr Windows](https://www.vultr.com)
   - [AWS Windows](https://aws.amazon.com/windows/)

2. **VPS Specifications**:
   ```
   OS: Windows Server 2019 or newer
   RAM: 4GB minimum, 8GB recommended
   CPU: 2 cores minimum
   Storage: 50GB SSD
   Location: Near your broker's servers
   ```

3. **Install on VPS**:
   ```powershell
   # Remote desktop into VPS

   # Download and install MT5
   # Visit your broker's website

   # Install Python 3.11
   # Download from python.org

   # Install Node.js
   # Download from nodejs.org

   # Clone/upload your project
   # Use FileZilla or Remote Desktop

   # Setup and run
   cd C:\path\to\NewBot
   python -m venv venv
   venv\Scripts\activate
   pip install -r requirements.txt
   python mt5_bridge.py
   ```

4. **Keep VPS Running**:
   - Don't close Remote Desktop - just disconnect
   - System stays running 24/7

## Option 2: Use Wine on macOS (For Development/Testing)

### Install Wine

```bash
# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Wine
brew install --cask wine-stable

# Or use CrossOver (commercial, easier)
# https://www.codeweavers.com/crossover
```

### Install MT5 via Wine

```bash
# Download MT5 installer from your broker
# Right-click installer.exe → Open With → Wine Stable

# Or via command line
wine ~/Downloads/mt5setup.exe
```

### Challenges with Wine
- Can be unstable
- Not suitable for live trading
- Good for testing EAs only
- Python MetaTrader5 package still won't work

## Option 3: Parallels/VMware (For Development)

### Using Parallels Desktop

1. **Install Parallels Desktop** ($99/year)
   - Download from [parallels.com](https://www.parallels.com)

2. **Create Windows VM**:
   ```
   - Windows 10 or 11
   - Allocate 4-8GB RAM
   - 50GB disk space
   - Bridge network adapter
   ```

3. **Install in Windows VM**:
   - MetaTrader 5
   - Python 3.11
   - Node.js
   - Your project files

4. **Share folders** between macOS and Windows VM

### Using VMware Fusion

Similar process to Parallels, free for personal use.

## Option 4: Hybrid Setup (Recommended for Development)

**Best of both worlds**: Develop on macOS, run MT5 bridge on Windows

### Architecture

```
┌──────────────────────────────────────────┐
│             macOS (Your Mac)             │
│  ├─ Backend (Node.js) ← localhost:5000  │
│  ├─ Development tools                    │
│  └─ Code editing                         │
└──────────────────┬───────────────────────┘
                   │ Network
┌──────────────────▼───────────────────────┐
│         Windows VPS/VM                   │
│  ├─ MT5 Terminal                         │
│  ├─ Expert Advisors                      │
│  └─ Python mt5_bridge.py                 │
└──────────────────────────────────────────┘
```

### Setup

**On macOS**:
```bash
cd backend
npm install
npm start
# Backend runs on http://localhost:5000
```

**On Windows VPS/VM**:
```powershell
# Edit .env
BACKEND_URL=http://your-mac-ip:5000  # or use ngrok
MT5_LOGIN=your_account
MT5_PASSWORD=your_password
MT5_SERVER=your_broker_server

# Run bridge
python mt5_bridge.py
```

## Option 5: Use EAs Without Python Bridge (Simplest)

The EAs can work **independently without the Python bridge**!

### Setup

1. **Just use the MT5 EAs**:
   - Run MT5 on Windows VPS/VM/Wine
   - Disable WebSocket in EA settings
   - EAs use local signal generation

2. **EA Settings**:
   ```
   Enable WebSocket: FALSE
   Enable Trading: TRUE
   # All other settings work normally
   ```

3. **What You Lose**:
   - No backend integration
   - No ML signals
   - No centralized logging to database
   - No WebSocket features

4. **What Still Works**:
   - All EA strategies
   - Risk management
   - Position management
   - Local logging in MT5
   - Trailing stops, break even, etc.

## Quick Start for macOS Users

### If You Just Want to Test EAs:

1. **Use Wine** (simplest for testing):
   ```bash
   brew install --cask wine-stable
   wine mt5setup.exe
   # Copy EAs to MT5 Experts folder in Wine
   # Run MT5 via Wine
   # Attach EAs with WebSocket disabled
   ```

2. **Or get a Windows VPS** (best for real trading):
   - Sign up for VPS
   - Install MT5, copy EAs
   - Set WebSocket to FALSE
   - Trade without Python bridge

### If You Want Full System:

1. **Backend on macOS**:
   ```bash
   cd backend
   npm install
   npm start
   ```

2. **Bridge + MT5 on Windows VPS**:
   - Get Windows VPS
   - Install MT5, Python 3.11, Node.js
   - Copy project files
   - Run bridge
   - Attach EAs

## Python Version Issues

### The Problem

```
ERROR: Could not find a version that satisfies the requirement MetaTrader5>=5.0.45
```

**Cause**: You have Python 3.13, but MetaTrader5 package only supports up to Python 3.11

### Solution

**Option A**: Install Python 3.11 alongside 3.13

```bash
# Using Homebrew
brew install python@3.11

# Create venv with Python 3.11
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Option B**: Use pyenv to manage Python versions

```bash
# Install pyenv
brew install pyenv

# Install Python 3.11
pyenv install 3.11.7

# Use it for this project
pyenv local 3.11.7

# Create venv
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Option C**: Skip MT5 bridge on macOS (if not needed)

```bash
# Install only other dependencies
pip install websockets python-dotenv requests aiohttp numpy colorlog

# Don't install MetaTrader5 package
# Run EAs without bridge on Windows VPS
```

## Recommended Setup for macOS Users

### For Development & Testing

```
Your Mac:
├─ Backend (Node.js)
├─ Code editing (VS Code)
├─ Development tools
└─ Git repository

Windows VM (Parallels/VMware):
├─ MT5 Terminal
├─ EAs attached to charts
├─ Python bridge (optional)
└─ Testing on demo account
```

### For Live Trading

```
Your Mac:
├─ Monitoring dashboard (optional)
└─ Code updates via Git

Windows VPS:
├─ MT5 Terminal (24/7)
├─ EAs attached to charts
├─ Python bridge
├─ Backend (Node.js)
└─ PostgreSQL database
```

## Common Issues & Solutions

### Issue 1: "MetaTrader5 package not found"

**Solution**:
- Use Python 3.8-3.11 (not 3.12/3.13)
- Or run bridge on Windows VPS instead
- Or skip bridge and use EAs standalone

### Issue 2: "Wine is too slow/crashes"

**Solution**:
- Use Parallels/VMware instead
- Or get Windows VPS
- Wine is only for testing, not production

### Issue 3: "Can't connect to MT5 from macOS"

**Solution**:
- MT5 must run on Windows
- Bridge must run where MT5 is running
- Backend can run anywhere (macOS is fine)

### Issue 4: "VPS is expensive"

**Solution**:
- Try Vultr ($10-15/month)
- Or AWS free tier for testing
- Or share VPS cost if trading multiple EAs
- Or use EAs without bridge (no VPS needed)

## Cost Comparison

| Option | Initial Cost | Monthly Cost | Best For |
|--------|-------------|--------------|----------|
| Wine | Free | Free | Testing only |
| Parallels | $99 | Free | Development |
| Windows VPS | ~$0 | $15-50 | Live trading |
| AWS | Free tier | $10-30 | Scalable production |
| EA-only (no bridge) | Free | Free | Simple trading |

## Testing on macOS

Even without MT5 running on macOS, you can:

1. **Test backend locally**:
   ```bash
   cd backend
   npm start
   curl http://localhost:5000/api/health
   ```

2. **Test bridge logic** (without MT5):
   - Mock MT5 responses
   - Test WebSocket server
   - Test API integration

3. **Backtest EAs** (on Windows VPS/VM):
   - Use MT5 Strategy Tester
   - No bridge needed for backtests

## Recommended Path

**For Most macOS Users**:

1. ✅ Develop backend on macOS
2. ✅ Get cheap Windows VPS ($15/month)
3. ✅ Install MT5 + EAs on VPS
4. ✅ Run bridge on VPS (connects to your backend)
5. ✅ Monitor from macOS via dashboard

**For Pure Testing**:

1. ✅ Install Wine on macOS
2. ✅ Run MT5 in Wine
3. ✅ Disable WebSocket in EAs
4. ✅ Test strategies on demo
5. ✅ Move to VPS when ready for live

**For Maximum Simplicity**:

1. ✅ Get Windows VPS
2. ✅ Install everything on VPS
3. ✅ Run entire system on VPS
4. ✅ Access via Remote Desktop
5. ✅ macOS just for monitoring

## Next Steps

Choose your option above, then:

1. Set up MT5 on Windows (VPS/VM/Wine)
2. Copy EAs to MT5 Experts folder
3. Compile EAs in MetaEditor
4. Configure settings
5. Test on demo account
6. Review logs and performance
7. Scale to live when ready

---

**Bottom Line**: macOS is great for development, but you need Windows for MT5. Use a VPS for trading, VM for development, or run EAs standalone without the bridge.

Questions? Check the main README.md or QUICKSTART.md for more details!
