#!/bin/bash
# Azure App Service startup script for Django

echo "Starting Django application on Azure..."

# Print Python version
python --version

# Install production dependencies (lighter than full requirements.txt)
echo "Installing production dependencies..."
pip install --no-cache-dir -r requirements-production.txt

# Run database migrations first
echo "Running database migrations..."
python manage.py migrate --noinput

# Skip collectstatic in production - Azure can serve static files directly
# Or run it in background to not block startup
echo "Skipping static files collection (handled by Azure or run in background)..."
# Uncomment below to collect static files (may take 2-5 minutes):
# python manage.py collectstatic --noinput --clear &

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
