web: cd Django && gunicorn health_assistant.wsgi:application --bind 0.0.0.0:$PORT --workers 3
release: cd Django && python manage.py migrate --noinput
