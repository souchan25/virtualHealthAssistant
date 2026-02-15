"""
WSGI config for health_assistant project.
"""

import os
import sys

# Add the Django directory to Python path
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'health_assistant.settings')

application = get_wsgi_application()
