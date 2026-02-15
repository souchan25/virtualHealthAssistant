#!/bin/bash

# Azure App Service Deployment Script for Django in Monorepo
# This script copies only the relevant Django backend files and ML models to the deployment target
# It avoids copying Vue frontend, Rasa chatbot, datasets, and huge dependencies

# 1. Set paths
# $DEPLOYMENT_SOURCE is usually the repo root
# $DEPLOYMENT_TARGET is usually wwwroot

echo "Starting Django Deployment..."

# 2. Sync Django Application Files
echo "Copying Django application files..."
rsync -av --delete \
    --exclude '__pycache__' \
    --exclude '*.pyc' \
    --exclude 'db.sqlite3' \
    --exclude 'media' \
    --exclude 'tests' \
    "$DEPLOYMENT_SOURCE/Django/" "$DEPLOYMENT_TARGET/Django/"

# 3. Sync ML Models (Required for backend)
echo "Copying ML models..."
mkdir -p "$DEPLOYMENT_TARGET/ML/models"
rsync -av --delete \
    "$DEPLOYMENT_SOURCE/ML/models/" "$DEPLOYMENT_TARGET/ML/models/"

# 4. Copy critical root files
cp "$DEPLOYMENT_SOURCE/Procfile" "$DEPLOYMENT_TARGET/" 2>/dev/null || true
cp "$DEPLOYMENT_SOURCE/runtime.txt" "$DEPLOYMENT_TARGET/" 2>/dev/null || true

# 5. Install Python Dependencies
echo "Installing dependencies..."
# Use Azure's virtual environment if available, otherwise create one
if [ ! -d "$DEPLOYMENT_TARGET/antenv" ]; then
    python3 -m venv "$DEPLOYMENT_TARGET/antenv"
fi
source "$DEPLOYMENT_TARGET/antenv/bin/activate"

pip install --upgrade pip
pip install -r "$DEPLOYMENT_TARGET/Django/requirements.txt"

# 6. Run Migrations & Collect Static
echo "Running Django management commands..."
cd "$DEPLOYMENT_TARGET/Django"
python manage.py collectstatic --noinput
python manage.py migrate --noinput

echo "Deployment finished successfully."
