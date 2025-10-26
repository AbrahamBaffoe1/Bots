# Python Version Fix Guide

## The Problem

```bash
ERROR: Could not find a version that satisfies the requirement MetaTrader5>=5.0.45 (from versions: none)
ERROR: No matching distribution found for MetaTrader5>=5.0.45
```

**Root Cause**: The `MetaTrader5` Python package does **not support Python 3.12 or 3.13**

**Supported versions**: Python 3.8, 3.9, 3.10, 3.11

## Quick Fix - Install Python 3.11

### Method 1: Using Homebrew (macOS)

```bash
# Install Python 3.11
brew install python@3.11

# Verify installation
python3.11 --version
# Should show: Python 3.11.x

# Remove old venv
cd /Users/kwamebaffoe/Desktop/EABot/NewBot
rm -rf venv

# Create new venv with Python 3.11
python3.11 -m venv venv

# Activate venv
source venv/bin/activate

# Verify you're using the right Python
python --version
# Should show: Python 3.11.x

# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt

# Should work now!
```

### Method 2: Using pyenv (Recommended for Managing Multiple Versions)

```bash
# Install pyenv
brew install pyenv

# Add to your shell config (~/.zshrc or ~/.bash_profile)
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init -)"' >> ~/.zshrc

# Restart shell or source config
source ~/.zshrc

# Install Python 3.11
pyenv install 3.11.7

# Set Python 3.11 for this project
cd /Users/kwamebaffoe/Desktop/EABot/NewBot
pyenv local 3.11.7

# Verify
python --version
# Should show: Python 3.11.7

# Remove old venv
rm -rf venv

# Create new venv
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

### Method 3: Download from Python.org

1. Go to https://www.python.org/downloads/
2. Download **Python 3.11.x** (latest 3.11 version)
3. Install it
4. Use it to create venv:

```bash
# Find where Python 3.11 was installed
which python3.11
# Usually /usr/local/bin/python3.11 or /Library/Frameworks/Python.framework/Versions/3.11/bin/python3.11

# Create venv with that Python
/usr/local/bin/python3.11 -m venv venv

# Activate and install
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

## Verify Installation

After installing, verify everything works:

```bash
# Activate venv
source venv/bin/activate

# Check Python version
python --version
# Should be 3.11.x

# Try importing MetaTrader5
python -c "import MetaTrader5 as mt5; print(f'MT5 version: {mt5.__version__}')"
# Should print version without errors

# Check all packages
pip list
# Should show MetaTrader5, websockets, etc.
```

## If You Still Get Errors

### Error: "MetaTrader5 not available on this platform"

This means you're on macOS. MetaTrader5 package is Windows-only.

**Solutions**:
1. Skip MT5 package on macOS (you only need it where MT5 runs)
2. Run the bridge on Windows VPS instead
3. See [MACOS_SETUP.md](MACOS_SETUP.md)

To install without MetaTrader5:
```bash
pip install websockets python-dotenv requests aiohttp numpy colorlog
```

### Error: "Command 'python3.11' not found"

Python 3.11 isn't installed or not in PATH.

**Fix**:
```bash
# Using Homebrew
brew install python@3.11

# Add to PATH if needed
echo 'export PATH="/usr/local/opt/python@3.11/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Alternative: Use Docker (Advanced)

If you want a consistent environment:

```dockerfile
# Create Dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

CMD ["python", "mt5_bridge.py"]
```

```bash
# Build and run
docker build -t mt5-bridge .
docker run mt5-bridge
```

## Run the Updated Setup Script

After fixing Python version:

```bash
cd /Users/kwamebaffoe/Desktop/EABot/NewBot

# Remove old venv
rm -rf venv

# Run setup (it will now check Python version)
./setup.sh
```

The updated setup script will:
1. Check your Python version
2. Warn if it's not compatible (3.12/3.13)
3. Give you instructions to fix
4. Handle macOS specially (skip MT5 package)

## Summary of Steps

1. **Install Python 3.11**:
   ```bash
   brew install python@3.11
   ```

2. **Remove old venv**:
   ```bash
   cd /Users/kwamebaffoe/Desktop/EABot/NewBot
   rm -rf venv
   ```

3. **Create new venv with 3.11**:
   ```bash
   python3.11 -m venv venv
   source venv/bin/activate
   ```

4. **Install dependencies**:
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

5. **Verify**:
   ```bash
   python --version  # Should be 3.11.x
   python -c "import MetaTrader5"  # Should not error (on Windows)
   ```

## What If I Want to Keep Python 3.13?

No problem! You can have multiple Python versions:

```bash
# Keep Python 3.13 as default
python --version  # 3.13

# Use Python 3.11 only for this project
cd /Users/kwamebaffoe/Desktop/EABot/NewBot
python3.11 -m venv venv
source venv/bin/activate
python --version  # Now shows 3.11 (only in this venv)

# When you deactivate, you're back to 3.13
deactivate
python --version  # Back to 3.13
```

## Platform-Specific Notes

### macOS
- MT5 package won't work anyway (Windows-only)
- You can skip it and run bridge on Windows VPS
- Or install in Wine/VM where MT5 actually runs

### Windows
- Python 3.11 from python.org works perfectly
- MetaTrader5 package will install fine
- No special configuration needed

### Linux
- Similar to macOS
- MT5 requires Wine
- Or run on Windows VPS

## Need Help?

If you're still stuck:

1. **Check Python version**:
   ```bash
   python --version
   python3 --version
   python3.11 --version
   ```

2. **Check pip version**:
   ```bash
   pip --version
   # Should show it's using Python 3.11
   ```

3. **Try installing MT5 directly**:
   ```bash
   pip install MetaTrader5==5.0.45
   # Shows exact error
   ```

4. **See what Python venv is using**:
   ```bash
   source venv/bin/activate
   which python
   python --version
   ```

---

**TL;DR**: Install Python 3.11, create new venv with it, reinstall packages. Done! ✅
