"""
Script to test each LLM provider individually to check status.
Run with: python Django/tests/test_individual_llms.py
"""
import os
import sys
import django
import json
import requests
from typing import Optional

# Setup Django environment
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'health_assistant.settings')
django.setup()

from django.conf import settings
from clinic.llm_service import AIInsightGenerator

def test_gemini():
    """Test Gemini using the user's specific snippet pattern"""
    print("\n" + "="*50)
    print("Testing GEMINI...")
    print("="*50)
    
    try:
        from google import genai
        
        api_key = getattr(settings, 'GEMINI_API_KEY', None)
        if not api_key:
            print("❌ GEMINI SKIPPED: No API Key found in settings.")
            return

        print(f"Initializing Gemini Client with key ending in ...{api_key[-4:] if api_key else 'None'}")
        
        # Using the specific snippet pattern requested by user
        client = genai.Client(api_key=api_key)
        
        # TEST 1: The user's requested model
        target_model = "gemini-3-flash-preview"
        print(f"\n[Test 1] Sending request to model='{target_model}'...")
        try:
            response = client.models.generate_content(
                model=target_model,
                contents="Explain how AI works in a few words",
            )
            print(f"✅ GEMINI SUCCESS ({target_model})!")
            print(f"Response: {response.text[:100]}...")
            return  # Exit if successful
        except Exception as e:
             print(f"❌ GEMINI ({target_model}) FAILED: {str(e)}")

        # TEST 2: Fallback to 2.0 Flash Lite (often has better free tier availability)
        fallback_model = "gemini-2.0-flash-lite-preview-02-05"
        print(f"\n[Test 2] Retrying with model='{fallback_model}'...")
        try:
            response = client.models.generate_content(
                model=fallback_model, 
                contents="Explain how AI works in a few words",
            )
            print(f"✅ GEMINI SUCCESS ({fallback_model})!")
            print(f"Response: {response.text[:100]}...")
            return
        except Exception as e:
            print(f"❌ GEMINI ({fallback_model}) FAILED: {str(e)}")

        # TEST 3: Fallback to 1.5 Flash (Most stable)
        stable_model = "gemini-1.5-flash"
        print(f"\n[Test 3] Retrying with model='{stable_model}'...")
        try:
            response = client.models.generate_content(
                model=stable_model, 
                contents="Explain how AI works in a few words",
            )
            print(f"✅ GEMINI SUCCESS ({stable_model})!")
            print(f"Response: {response.text[:100]}...")
        except Exception as e:
            print(f"❌ GEMINI ({stable_model}) FAILED: {str(e)}")
            
    except ImportError:
        print("❌ GEMINI FAILED: google-genai package not installed")
    except Exception as e:
        print(f"❌ GEMINI FAILED: {str(e)}")
        # Try fallback model name if the specific one failed
        if "404" in str(e) or "not found" in str(e).lower():
            print("\nRetrying with 'gemini-1.5-flash'...")
            try:
                response = client.models.generate_content(
                    model="gemini-1.5-flash",
                    contents="Explain how AI works in a few words",
                )
                print("✅ GEMINI SUCCESS (with gemini-1.5-flash)!")
                print(f"Response: {response.text[:100]}...")
            except Exception as e2:
                print(f"❌ GEMINI RETRY FAILED: {str(e2)}")

def test_groq(ai_gen):
    """Test Groq direct connection"""
    print("\n" + "="*50)
    print("Testing GROQ...")
    print("="*50)
    
    if not ai_gen.groq_client:
        print("❌ GROQ SKIPPED: Client not initialized (check API key)")
        return

    try:
        print("Sending request to Groq...")
        response = ai_gen.groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": "Say hello"}],
            max_tokens=10
        )
        result = response.choices[0].message.content
        print("✅ GROQ SUCCESS!")
        print(f"Response: {result}")
    except Exception as e:
        print(f"❌ GROQ FAILED: {str(e)}")

def test_openrouter(ai_gen):
    """Test OpenRouter direct connection"""
    print("\n" + "="*50)
    print("Testing OPENROUTER...")
    print("="*50)
    
    if not ai_gen.openrouter_api_key:
        print("❌ OPENROUTER SKIPPED: No API Key")
        return

    try:
        print("Sending request to OpenRouter...")
        response = requests.post(
            url="https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {ai_gen.openrouter_api_key}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://cpsu-health-assistant.edu.ph",
                "X-Title": "CPSU Virtual Health Assistant",
            },
            json={
                "model": "stepfun/step-3.5-flash:free", # Using a potentially more reliable free model
                "messages": [{"role": "user", "content": "Say hello"}],
                "max_tokens": 10
            },
            timeout=30
        )
        
        if response.status_code == 200:
            content = response.json()['choices'][0]['message']['content']
            print("✅ OPENROUTER SUCCESS!")
            print(f"Response: {content}")
        else:
            print(f"❌ OPENROUTER FAILED: Status {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"❌ OPENROUTER FAILED: {str(e)}")

def test_cohere(ai_gen):
    """Test Cohere direct connection"""
    print("\n" + "="*50)
    print("Testing COHERE...")
    print("="*50)
    
    if not ai_gen.cohere_client:
        print("❌ COHERE SKIPPED: Client not initialized")
        return

    try:
        print("Sending request to Cohere...")
        response = ai_gen.cohere_client.chat(
            message="Say hello",
            max_tokens=10
        )
        print("✅ COHERE SUCCESS!")
        print(f"Response: {response.text}")
    except Exception as e:
        print(f"❌ COHERE FAILED: {str(e)}")

if __name__ == "__main__":
    # Configure logging to console
    import logging
    logging.basicConfig(level=logging.INFO)
    
    print("Starting test script...")
    
    try:
        print("Initializing AI Service...")
        ai_gen = AIInsightGenerator()
        print("AI Service Initialized.")
    except Exception as e:
        print(f"FAILED to initialize AI Service: {e}")
        ai_gen = type('obj', (object,), {
            'groq_client': None, 'openrouter_api_key': None, 'cohere_client': None
        })
    
    test_gemini()
    test_groq(ai_gen)
    test_openrouter(ai_gen)
    test_cohere(ai_gen)
