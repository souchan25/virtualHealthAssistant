#!/bin/bash
set -e  # Exit on error

echo "Starting CPSU Health Assistant Backend..."

# Ensure dependencies are installed
echo "Checking Python dependencies..."
pip install --no-cache-dir -r /home/site/wwwroot/Django/requirements.txt || pip install --no-cache-dir -r requirements.txt

# Navigate to Django directory
cd /home/site/wwwroot/Django 2>/dev/null || cd Django

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
