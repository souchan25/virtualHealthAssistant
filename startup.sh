#!/bin/bash
cd Django
python manage.py migrate
gunicorn --bind=0.0.0.0 --timeout 600 health_assistant.wsgi
