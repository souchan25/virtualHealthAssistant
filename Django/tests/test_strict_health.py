"""
Test strict health scope enforcement.
"""
import os
import sys
import django

# Setup Django environment
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'health_assistant.settings')
django.setup()

from clinic.llm_service import AIInsightGenerator

def test_spaghetti_ingredients():
    print("=" * 60)
    print("TESTING STRICT HEALTH SCOPE")
    print("=" * 60)
    
    ai_gen = AIInsightGenerator()
    
    # Non-health query
    test_message = "anung ingredients ng spaghetti"
    print(f"\nUser Query: '{test_message}'")
    
    print("\nGenerating response (Gemini/Groq/OpenRouter)...")
    response = ai_gen.generate_chat_response(test_message)
    
    print(f"\nAI Response:\n{'-'*20}\n{response}\n{'-'*20}")
    
    # Basic check
    if "ingredient" in response.lower() and "tomato" in response.lower():
        print("❌ FAIL: AI provided a recipe.")
    elif "health" in response.lower() or "medical" in response.lower() or "clinic" in response.lower():
        print("✅ PASS: AI refused or redirected to health.")
    else:
        print("⚠️ UNCERTAIN: Check response manually.")

if __name__ == "__main__":
    test_spaghetti_ingredients()
