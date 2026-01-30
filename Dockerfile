# Multi-stage build for Django backend
FROM python:3.11-slim as builder

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (for better caching)
COPY Django/requirements.txt /app/Django/
RUN pip install --no-cache-dir -r Django/requirements.txt

# Copy ML training data and scripts
COPY ML /app/ML

# Train ML model
RUN cd /app/ML/scripts && python train_model_realistic.py

# Final stage
FROM python:3.11-slim

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy Python packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy trained ML model
COPY --from=builder /app/ML /app/ML

# Copy Django application
COPY Django /app/Django

# Collect static files
WORKDIR /app/Django
RUN python manage.py collectstatic --noinput

# Create non-root user
RUN useradd -m -u 1000 django && chown -R django:django /app
USER django

# Expose port
EXPOSE 8000

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=health_assistant.settings

# Run migrations and start server
CMD ["sh", "-c", "python manage.py migrate --noinput && gunicorn health_assistant.wsgi:application --bind 0.0.0.0:8000 --workers 3"]
