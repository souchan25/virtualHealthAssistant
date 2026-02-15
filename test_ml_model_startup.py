#!/usr/bin/env python3
"""
Test script to verify ML model loading and Gunicorn startup.
This test ensures the fix for the Gunicorn WSGI import error is working.

Important: This test must be run from the repository root directory.
The script expects the following structure:
  - Repository root/
    ├── test_ml_model_startup.py (this file)
    ├── ML/models/disease_predictor_v2.pkl
    └── Django/health_assistant/

Usage:
    cd /path/to/virtualHealthAssistant
    python test_ml_model_startup.py
"""

import os
import sys
from pathlib import Path

# Ensure we're running from the repository root
REPO_ROOT = Path(__file__).parent.resolve()
os.chdir(REPO_ROOT)

def test_ml_model_exists():
    """Test that the ML model file exists"""
    print("=" * 60)
    print("TEST 1: Checking ML Model File")
    print("=" * 60)
    
    model_path = REPO_ROOT / 'ML' / 'models' / 'disease_predictor_v2.pkl'
    
    if model_path.exists():
        size_mb = model_path.stat().st_size / (1024 * 1024)
        print(f"✓ ML model found: {model_path}")
        print(f"✓ Model size: {size_mb:.2f} MB")
        return True
    else:
        print(f"✗ ML model NOT found at: {model_path}")
        print("\nTo fix: Run the training script:")
        print("  cd ML/scripts")
        print("  python train_model_realistic.py")
        return False

def test_django_import():
    """Test that Django can import without errors"""
    print("\n" + "=" * 60)
    print("TEST 2: Django WSGI Import")
    print("=" * 60)
    
    # Set minimal environment variables
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'health_assistant.settings')
    os.environ.setdefault('SECRET_KEY', 'test-key-for-import-check')
    os.environ.setdefault('DEBUG', 'False')
    os.environ.setdefault('DATABASE_URL', 'sqlite:///db.sqlite3')
    os.environ.setdefault('ALLOWED_HOSTS', '*')
    
    # Add Django to path
    django_path = REPO_ROOT / 'Django'
    sys.path.insert(0, str(django_path))
    
    try:
        import health_assistant.wsgi
        print("✓ Django WSGI module imported successfully!")
        return True
    except Exception as e:
        print(f"✗ Django import failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_ml_service():
    """Test that ML service can load the model"""
    print("\n" + "=" * 60)
    print("TEST 3: ML Service Initialization")
    print("=" * 60)
    
    try:
        from clinic.ml_service import get_ml_predictor
        predictor = get_ml_predictor()
        
        print(f"✓ ML Predictor loaded successfully!")
        print(f"✓ Model has {len(predictor.feature_names)} features")
        
        # Test a simple prediction
        test_symptoms = ['fever', 'cough']
        result = predictor.predict(test_symptoms)
        
        print(f"✓ Test prediction successful!")
        print(f"  Disease: {result['predicted_disease']}")
        print(f"  Confidence: {result['confidence_score']:.2%}")
        
        return True
    except Exception as e:
        print(f"✗ ML service failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Run all tests"""
    print("\n" + "=" * 60)
    print("ML MODEL STARTUP TEST SUITE")
    print("=" * 60)
    
    results = []
    
    # Run tests
    results.append(("ML Model File", test_ml_model_exists()))
    results.append(("Django WSGI Import", test_django_import()))
    results.append(("ML Service", test_ml_service()))
    
    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    
    all_passed = True
    for test_name, passed in results:
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"{status}: {test_name}")
        if not passed:
            all_passed = False
    
    print("=" * 60)
    
    if all_passed:
        print("\n✅ All tests passed! Gunicorn should start successfully.")
        return 0
    else:
        print("\n❌ Some tests failed. Fix the issues before deploying.")
        return 1

if __name__ == '__main__':
    sys.exit(main())
