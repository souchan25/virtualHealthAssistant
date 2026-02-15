import multiprocessing
import os

# Binding
bind = f"0.0.0.0:{os.getenv('PORT', '8000')}"

# Worker processes
workers = int(os.getenv('WEB_CONCURRENCY', '2'))
worker_class = 'sync'
worker_connections = 1000

# Timeouts
timeout = 120  # 2 minutes
graceful_timeout = 120
keepalive = 5

# Restart workers after this many requests to prevent memory leaks
max_requests = 1000
max_requests_jitter = 50

# Logging
accesslog = '-'
errorlog = '-'
loglevel = 'info'

# Process naming
proc_name = 'cpsu-health-assistant'

# Server mechanics
daemon = False
pidfile = None
umask = 0
user = None
group = None
tmp_upload_dir = None

# Preloading (disabled to avoid loading ML models at startup)
preload_app = False
