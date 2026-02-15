#!/bin/bash

# ===================================
# CPSU Virtual Health Assistant
# Render Build Script
# ===================================

set -e  # Exit on error

echo "======================================"
echo "Starting Render Build Process"
echo "======================================"

# 1. Install Dependencies
echo ""
echo "--- Step 1: Installing Dependencies ---"
pip install --upgrade pip
pip install -r Django/requirements.txt

# 2. Train ML Model
# We need to train the model so it's available for the backend
echo ""
echo "--- Step 2: Training ML Model ---"
cd ML/scripts
# Using the realistic model training script as requested
if [ -f "train_model_realistic.py" ]; then
    echo "Running train_model_realistic.py..."
    python train_model_realistic.py
else
    echo "Warning: train_model_realistic.py not found. Checking for train_model_v2.py..."
    if [ -f "train_model_v2.py" ]; then
        echo "Running train_model_v2.py..."
        python train_model_v2.py
    else
        echo "Error: No training script found!"
        exit 1
    fi
fi
cd ../..

# 3. Django Setup
echo ""
echo "--- Step 3: Setting up Django ---"
cd Django

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Run migrations
echo "Running database migrations..."
python manage.py migrate --noinput

echo ""
echo "======================================"
echo "Build Complete Successfully!"
echo "======================================"
