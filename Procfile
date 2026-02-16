web: gunicorn health_assistant.wsgi:application --bind 0.0.0.0:$PORT --workers 2 --timeout 120 --graceful-timeout 120 --keep-alive 5 --log-level info --chdir Django
release: python manage.py migrate --noinput
