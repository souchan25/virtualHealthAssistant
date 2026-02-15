# Gunicorn Worker Error Fix - ML Model Training

## Problem Statement

Gunicorn workers were crashing during startup with an import error:

```
[ERROR] Exception in worker process
Traceback (most recent call last):
  File "/opt/python/3.11.14/lib/python3.11/site-packages/gunicorn/arbiter.py", line 641, in spawn_worker
    worker.init_process()
  ...
```

## Root Cause

The ML model file (`ML/models/disease_predictor_v2.pkl`) was missing in the deployment environment. When Django's WSGI application was loaded:

1. Gunicorn imports `health_assistant.wsgi`
2. Django initializes and imports `clinic` app
3. Views import `ml_service.py`
4. On first API call, `MLPredictor.__init__()` tries to load the missing model file
5. Worker crashes with FileNotFoundError

**Note**: ML model files are not committed to git due to their size (~32MB). They must be generated during deployment.

## Solution

### 1. Updated `startup.sh`

Added ML model training step before starting Gunicorn:

```bash
# Train ML model if it doesn't exist
echo "Checking ML model..."
if [ ! -f "ML/models/disease_predictor_v2.pkl" ]; then
    echo "ML model not found. Training model..."
    cd ML/scripts
    python train_model_realistic.py
    cd ../..
    
    # Verify model was created
    if [ ! -f "ML/models/disease_predictor_v2.pkl" ]; then
        echo "ERROR: ML model training failed!"
        exit 1
    fi
    echo "✓ ML model trained successfully"
else
    echo "✓ ML model found"
fi
```

**Benefits**:
- Automatically trains model if missing (resilient deployment)
- Fails fast if training fails (clear error messages)
- Skips training if model already exists (faster restarts)

### 2. Updated `Dockerfile`

Added ML model training during Docker image build:

```dockerfile
# Train ML model during build
WORKDIR /app/ML/scripts
RUN python train_model_realistic.py && \
    echo "✓ ML model trained successfully" && \
    test -f /app/ML/models/disease_predictor_v2.pkl || (echo "ERROR: Model file not found!" && exit 1)
```

**Benefits**:
- Model is built into Docker image
- Build fails if training fails (caught before deployment)
- No runtime training needed for Docker deployments

## Verification

Run the test suite to verify the fix:

```bash
python test_ml_model_startup.py
```

Expected output:
```
✅ All tests passed! Gunicorn should start successfully.
```

## Manual Testing

### Test 1: Verify ML Model Exists
```bash
ls -lh ML/models/disease_predictor_v2.pkl
# Should show: ~32MB file
```

### Test 2: Test Django Import
```bash
cd Django
python -c "
import os
os.environ['SECRET_KEY'] = 'test'
os.environ['DATABASE_URL'] = 'sqlite:///db.sqlite3'
import health_assistant.wsgi
print('✓ WSGI imports successfully')
"
```

### Test 3: Test Gunicorn Startup
```bash
cd Django
SECRET_KEY='test' DATABASE_URL='sqlite:///db.sqlite3' \
gunicorn --bind=0.0.0.0:8000 --workers=1 --timeout=30 \
health_assistant.wsgi:application
# Should start without errors
```

## Model Training Details

**Script**: `ML/scripts/train_model_realistic.py`

**Training Time**: ~60-90 seconds

**Accuracy**: 85-95% (realistic range for medical diagnosis)

**Model Size**: ~32 MB

**Features**: 132 symptoms

**Diseases**: 41 unique conditions

## Deployment Considerations

### For Azure Web Apps
- ✅ CI/CD workflow trains model during build phase
- ✅ `startup.sh` provides fallback if model missing
- ✅ Model included in deployment package

### For Docker Containers
- ✅ Model trained during Docker build
- ✅ Build fails if training fails
- ✅ No runtime training needed

### For Local Development
Run training once:
```bash
cd ML/scripts
python train_model_realistic.py
```

Then start Django normally:
```bash
cd Django
python manage.py runserver
```

## Related Files

- `startup.sh` - Startup script with ML training
- `Dockerfile` - Docker build with ML training
- `ML/scripts/train_model_realistic.py` - Training script
- `Django/clinic/ml_service.py` - ML service (loads model)
- `.github/workflows/azure-django-backend.yml` - CI/CD workflow
- `test_ml_model_startup.py` - Verification test suite

## Troubleshooting

### Issue: "ML model not found" error

**Solution**: Train the model manually:
```bash
cd ML/scripts
python train_model_realistic.py
```

### Issue: Training script fails

**Possible causes**:
1. Missing dependencies: `pip install pandas numpy scikit-learn`
2. Missing dataset files: Check `ML/Datasets/active/` has CSV files
3. Insufficient memory: Training needs ~1GB RAM

### Issue: Model loads but predictions fail

**Solution**: Retrain the model with clean environment:
```bash
cd ML/scripts
rm ../models/disease_predictor_v2.pkl
python train_model_realistic.py
```

## Security Note

ML models are excluded from git (see `.gitignore`):
```
ML/models/*.pkl
ML/models/*.h5
ML/models/*.pth
```

This is intentional to:
- Keep repository size small
- Prevent committing large binary files
- Allow environment-specific model training
- Enable model versioning via training scripts

## Performance Impact

**First Deployment**:
- Training time: ~90 seconds
- One-time cost during build/startup

**Subsequent Deployments**:
- If model exists: No training (instant)
- If model missing: Trains automatically (~90 seconds)

**Runtime Performance**:
- Model loads once at first API call
- Singleton pattern: Cached in memory
- Prediction latency: <100ms
