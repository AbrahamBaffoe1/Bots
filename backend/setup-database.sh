#!/bin/bash

# Smart Stock Trader Database Setup Script
# This script creates the database and runs the SQL setup

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  Smart Stock Trader - Database Setup                 ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "⚠️  .env file not found. Creating from .env.example..."
    cp .env.example .env
    echo "✓ .env file created. Please edit it with your database credentials."
    echo ""
    read -p "Press Enter to continue after editing .env file..."
fi

# Database credentials from .env
DB_NAME=${DB_NAME:-smartstocktrader}
DB_USER=${DB_USER:-postgres}
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}

echo "Database Configuration:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL is not installed or not in PATH"
    echo ""
    echo "Please install PostgreSQL:"
    echo "  macOS: brew install postgresql"
    echo "  Ubuntu: sudo apt-get install postgresql"
    echo "  Windows: Download from https://www.postgresql.org/download/"
    exit 1
fi

echo "✓ PostgreSQL found"
echo ""

# Check if database exists
DB_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" 2>/dev/null)

if [ "$DB_EXISTS" = "1" ]; then
    echo "⚠️  Database '$DB_NAME' already exists"
    read -p "Do you want to drop and recreate it? (yes/no): " -r
    echo ""
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        echo "Dropping database '$DB_NAME'..."
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "DROP DATABASE $DB_NAME;" 2>/dev/null
        echo "✓ Database dropped"
    else
        echo "Using existing database '$DB_NAME'"
    fi
fi

# Create database if it doesn't exist
if [ "$DB_EXISTS" != "1" ] || [[ $REPLY =~ ^[Yy]es$ ]]; then
    echo "Creating database '$DB_NAME'..."
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "CREATE DATABASE $DB_NAME;" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✓ Database created successfully"
    else
        echo "❌ Failed to create database"
        exit 1
    fi
fi

echo ""
echo "Running SQL setup script..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Run the SQL setup script
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f database-setup.sql

if [ $? -eq 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║  ✓ Database setup completed successfully!            ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""
    echo "Next steps:"
    echo "  1. Start the server: npm run dev"
    echo "  2. Test the API: curl http://localhost:5000/health"
    echo ""
else
    echo ""
    echo "❌ Database setup failed"
    exit 1
fi
