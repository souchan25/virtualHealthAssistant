#!/bin/bash
# Azure App Service startup script for Django

echo "Starting Django application on Azure..."

# Print Python version
python --version

# Upgrade pip
python -m pip install --upgrade pip

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Run database migrations
echo "Running database migrations..."
python manage.py migrate --noinput

# Create default superuser if needed (optional)
# python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', 'admin@example.com', 'changeme')"

# Start Gunicorn
echo "Starting Gunicorn server..."
gunicorn health_assistant.wsgi:application \
    --bind=0.0.0.0:8000 \
    --workers=4 \
    --timeout=600 \
    --access-logfile='-' \
    --error-logfile='-' \
    --log-level=info
