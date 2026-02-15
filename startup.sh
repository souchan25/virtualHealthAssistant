#!/bin/bash
set -e  # Exit on error

echo "Starting CPSU Health Assistant Backend..."

# Navigate to project root first to ensure correct paths
cd /home/site/wwwroot 2>/dev/null || cd "$(dirname "$0")"

# Train ML model if it doesn't exist
echo "Checking ML model..."
if [ ! -f "ML/models/disease_predictor_v2.pkl" ]; then
    echo "ML model not found. Training model..."
    # Use subshell to isolate directory change
    (cd ML/scripts && python train_model_realistic.py) || {
        echo "ERROR: ML model training failed!"
        exit 1
    }
    
    # Verify model was created
    if [ ! -f "ML/models/disease_predictor_v2.pkl" ]; then
        echo "ERROR: ML model file not found after training!"
        exit 1
    fi
    echo "✓ ML model trained successfully"
else
    echo "✓ ML model found"
fi

# Navigate to Django directory
cd Django

echo "Running database migrations..."
python manage.py migrate --noinput

echo "Collecting static files..."
python manage.py collectstatic --noinput

echo "Starting Gunicorn server..."
# Use gunicorn config file if available, otherwise use default settings
if [ -f "gunicorn.conf.py" ]; then
    exec gunicorn -c gunicorn.conf.py health_assistant.wsgi:application
else
    exec gunicorn --bind=0.0.0.0:${PORT:-8000} \
                  --workers=${WEB_CONCURRENCY:-2} \
                  --timeout=120 \
                  --access-logfile=- \
                  --error-logfile=- \
                  health_assistant.wsgi:application
fi
