# ===================================
# CPSU Virtual Health Assistant
# Django Backend Dockerfile
# ===================================

FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (for better caching)
COPY Django/requirements.txt /app/requirements.txt

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Copy project files
COPY Django/ /app/Django/
COPY ML/ /app/ML/

# Train ML model during build
WORKDIR /app/ML/scripts
RUN python train_model_realistic.py && \
    echo "✓ ML model trained successfully" && \
    test -f /app/ML/models/disease_predictor_v2.pkl || (echo "ERROR: Model file not found!" && exit 1)

# Create necessary directories
RUN mkdir -p /app/Django/logs /app/Django/staticfiles /app/Django/media

# Collect static files
WORKDIR /app/Django
RUN python manage.py collectstatic --noinput || true

# Create a non-root user
RUN useradd -m -u 1000 django && \
    chown -R django:django /app
USER django

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/api/health/', timeout=5)" || exit 1

# Run gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "--timeout", "60", "health_assistant.wsgi:application"]
