#!/bin/bash
set -e

echo "Starting CPSU Django Backend..."

# Train ML model if needed
if [ ! -f "ML/models/disease_predictor_v2.pkl" ]; then
    echo "Training ML model..."
    python ML/scripts/train_model_realistic.py
fi

# Install dependencies
echo "Installing dependencies..."
pip install -r Django/requirements.txt

# Run migrations
echo "Running migrations..."
cd Django
python manage.py migrate --noinput

# Start Gunicorn
echo "Starting Gunicorn..."
exec gunicorn health_assistant.wsgi:application \
    --bind 0.0.0.0:${PORT:-8000} \
    --workers ${WEB_CONCURRENCY:-2} \
    --timeout 120 \
    --graceful-timeout 120 \
    --keep-alive 5 \
    --log-level info