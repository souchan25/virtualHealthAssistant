"""
Generate a new Django SECRET_KEY
Run this script to generate a secure secret key for your .env file

Usage:
    python generate_secret_key.py
"""

from django.core.management.utils import get_random_secret_key

if __name__ == '__main__':
    secret_key = get_random_secret_key()
    print("\n" + "="*60)
    print("Generated Django SECRET_KEY:")
    print("="*60)
    print(f"\n{secret_key}\n")
    print("="*60)
    print("Add this to your Django/.env file:")
    print("="*60)
    print(f"DJANGO_SECRET_KEY={secret_key}")
    print("="*60 + "\n")
