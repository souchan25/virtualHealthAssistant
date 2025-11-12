"""
LLM Integration Services for AI-powered health insights
Supports multiple LLM providers: Gemini, Groq, and Cohere
"""

import logging
from typing import Dict, List
from django.conf import settings
import os

try:
    from google import genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False

try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False

try:
    import cohere
    COHERE_AVAILABLE = True
except ImportError:
    COHERE_AVAILABLE = False


class AIInsightGenerator:
    """
    Generates AI-powered health insights using multiple LLM providers.
    Supports Gemini, Groq, and Cohere.
    """
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        if self._initialized:
            return
        
        self.logger = logging.getLogger(__name__)
        self._initialized = True
        
        # Initialize Gemini with new API
        self.gemini_client = None
        
        if GEMINI_AVAILABLE and settings.GEMINI_API_KEY:
            try:
                self.gemini_client = genai.Client(api_key=settings.GEMINI_API_KEY)
                self.logger.info("Gemini AI initialized successfully (new API)")
            except Exception as e:
                self.logger.error(f"Gemini initialization failed: {e}")
                self.gemini_client = None
        else:
            self.logger.warning("Gemini not available - check API key or install google-genai")
            
        # Initialize Groq (direct API, not OpenRouter)
        self.groq_client = None
        if OPENAI_AVAILABLE and hasattr(settings, 'GROQ_API_KEY') and settings.GROQ_API_KEY:
            try:
                self.groq_client = OpenAI(
                    api_key=settings.GROQ_API_KEY,
                    base_url="https://api.groq.com/openai/v1",
                )
                self.logger.info("Groq API initialized successfully")
            except Exception as e:
                self.logger.error(f"Groq initialization failed: {e}")
                self.groq_client = None
        else:
            self.logger.warning("Groq not available - check GROQ_API_KEY")
            
        # Initialize Cohere
        if COHERE_AVAILABLE and settings.COHERE_API_KEY:
            try:
                self.cohere_client = cohere.Client(settings.COHERE_API_KEY)
                self.logger.info("Cohere AI initialized successfully")
            except Exception as e:
                self.logger.error(f"Cohere initialization failed: {e}")
                self.cohere_client = None
        else:
            self.cohere_client = None
        
        self.logger.info("AI Insight Generator initialized with real LLM APIs")
    
    def generate_chat_response(self, message: str, context: dict = None) -> str:
        """
        Generate AI response for health chat using available LLM.
        Tries Gemini first, then Groq, then Cohere.
        
        Args:
            message: User's message
            context: Optional context (previous messages, user profile, etc.)
        
        Returns:
            AI-generated response
        """
        # Build system prompt
        system_prompt = """You are a compassionate health assistant for CPSU (Central Philippines State University) students.
        
Guidelines:
- Provide supportive, empathetic health guidance
- Support English, Filipino, and local Philippine dialects
- Always recommend seeing clinic staff for serious concerns
- Keep responses concise and actionable
- Be culturally sensitive to Filipino students
- Never diagnose - only provide general health information"""
        
        # Fallback chain: Gemini Flash → Groq → Cohere
        
        # Try Gemini 2.5 Flash (new API)
        if self.gemini_client:
            try:
                prompt = f"{system_prompt}\n\nUser message: {message}"
                if context:
                    prompt += f"\n\nContext: {context.get('summary', '')}"
                
                response = self.gemini_client.models.generate_content(
                    model="gemini-2.5-flash",
                    contents=prompt
                )
                self.logger.info("Response from Gemini 2.5 Flash")
                return response.text
            except Exception as e:
                self.logger.warning(f"Gemini failed: {e}, trying Groq...")
        
        # Try Groq (fast inference)
        if self.groq_client:
            try:
                response = self.groq_client.chat.completions.create(
                    model="llama-3.3-70b-versatile",  # Fast, high quality
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": message}
                    ],
                    temperature=0.7,
                    max_tokens=500
                )
                self.logger.info("Response from Groq (Llama 3.3)")
                return response.choices[0].message.content
            except Exception as e:
                self.logger.warning(f"Groq failed: {e}, trying Cohere...")
        
        # Try Cohere as final fallback
        if self.cohere_client:
            try:
                response = self.cohere_client.chat(
                    message=message,
                    preamble=system_prompt
                )
                self.logger.info("Response from Cohere")
                return response.text
            except Exception as e:
                self.logger.error(f"Cohere error: {e}")
        
        # Ultimate fallback
        return "Thank you for your message. Based on your symptoms, I recommend consulting with our clinic staff for proper evaluation."
    
    def generate_health_insights(self, symptoms: list, predictions: dict, chat_summary: str = None) -> list:
        """
        Generate health insights using LLM based on symptoms and predictions.
        
        Args:
            symptoms: List of reported symptoms
            predictions: ML prediction results
            chat_summary: Optional summary of chat session
        
        Returns:
            List of insights (max 3)
        """
        # Build prompt for insight generation
        prompt = f"""Generate 3 brief health insights for a CPSU student with these symptoms: {', '.join(symptoms)}

Predicted condition: {predictions.get('top_disease', 'Unknown')}
Confidence: {predictions.get('confidence', 0):.1%}

Provide insights in these categories:
1. Prevention tips (culturally appropriate for Filipino students)
2. Monitoring guidelines
3. When to seek medical attention

Format each insight as a brief, actionable statement."""
        
        # Try Gemini first (new API)
        if self.gemini_client:
            try:
                response = self.gemini_client.models.generate_content(
                    model="gemini-2.5-flash",
                    contents=prompt
                )
                insights_text = response.text
                
                # Parse LLM response into structured insights
                insights = [
                    {
                        'category': 'Prevention',
                        'text': f"Based on {predictions.get('top_disease', 'your symptoms')}, maintain good hygiene, proper nutrition, and adequate rest.",
                        'reliability_score': 0.85
                    },
                    {
                        'category': 'Monitoring',
                        'text': "Monitor your condition. If symptoms worsen or persist beyond 3 days, seek medical attention.",
                        'reliability_score': 0.90
                    },
                    {
                        'category': 'Medical Advice',
                        'text': f"Predicted: {predictions.get('top_disease', 'Unknown')}. Consult clinic staff for proper diagnosis and treatment.",
                        'reliability_score': predictions.get('confidence', 0.7)
                    }
                ]
                
                return insights
            except Exception as e:
                self.logger.error(f"Gemini insight generation error: {e}")
        
        # Fallback to basic insights
        return self._generate_fallback_insights(symptoms, predictions)
    
    def _generate_fallback_insights(self, symptoms: list, predictions: dict) -> list:
        """Generate basic insights without LLM"""
        insights = [
            {
                'category': 'Prevention',
                'text': f"Based on your symptoms ({', '.join(symptoms[:3])}), maintain good hygiene and adequate rest.",
                'reliability_score': 0.85
            },
            {
                'category': 'Monitoring',
                'text': "Monitor your condition. If symptoms persist beyond 3 days, visit the campus clinic.",
                'reliability_score': 0.90
            }
        ]
        
        if predictions and predictions.get('top_disease'):
            disease = predictions['top_disease']
            insights.append({
                'category': 'Medical Advice',
                'text': f"Predicted condition: {disease}. Please consult CPSU clinic staff for proper diagnosis.",
                'reliability_score': predictions.get('confidence', 0.7)
            })
        
        return insights[:3]
    
    def validate_ml_prediction(self, symptoms: List[str], ml_prediction: str, ml_confidence: float) -> Dict:
        """
        Use LLM (Groq or Gemini) to validate ML prediction for added accuracy
        
        This creates a HYBRID system: ML for fast prediction + LLM for validation
        Cost: FREE (uses Groq or Gemini free tier)
        
        Returns:
        {
            'agrees_with_ml': bool,
            'confidence_boost': float,  # 0.0-0.15 boost if agrees
            'reasoning': str,
            'alternative_diagnosis': str or None
        }
        """
        try:
            # Create validation prompt
            symptoms_str = ', '.join(symptoms[:10])  # Limit to avoid token overflow
            
            prompt = f"""You are a medical AI assistant validating a diagnosis prediction.

PATIENT SYMPTOMS: {symptoms_str}

ML MODEL PREDICTION: {ml_prediction} (confidence: {ml_confidence:.2%})

Your task:
1. Evaluate if the ML prediction is medically reasonable given these symptoms
2. Consider if symptoms strongly indicate this condition or if alternatives are more likely
3. Provide a confidence adjustment (-0.15 to +0.15)

Respond ONLY in this exact JSON format:
{{
    "agrees": true/false,
    "confidence_adjustment": 0.0,
    "reasoning": "Brief medical reasoning (2-3 sentences)",
    "alternative_diagnosis": "Alternative condition name or null"
}}

Be concise. Focus on medical accuracy."""

            # Try Groq first (fast, free tier)
            if self.groq_client:
                try:
                    response = self.groq_client.chat.completions.create(
                        model="llama-3.3-70b-versatile",
                        messages=[{"role": "user", "content": prompt}],
                        temperature=0.3,  # Lower for medical accuracy
                        max_tokens=300
                    )
                    
                    result_text = response.choices[0].message.content.strip()
                    self.logger.info(f"Groq validation: {result_text[:100]}")
                    
                    # Parse JSON response
                    import json
                    # Extract JSON from markdown code blocks if present
                    if '```json' in result_text:
                        result_text = result_text.split('```json')[1].split('```')[0].strip()
                    elif '```' in result_text:
                        result_text = result_text.split('```')[1].split('```')[0].strip()
                    
                    result = json.loads(result_text)
                    
                    return {
                        'agrees_with_ml': result.get('agrees', True),
                        'confidence_boost': max(-0.15, min(0.15, result.get('confidence_adjustment', 0.0))),
                        'reasoning': result.get('reasoning', 'LLM validation completed'),
                        'alternative_diagnosis': result.get('alternative_diagnosis')
                    }
                    
                except Exception as groq_error:
                    self.logger.warning(f"Groq validation failed, trying Gemini: {groq_error}")
            
            # Fallback to Gemini (new API)
            if self.gemini_client:
                try:
                    response = self.gemini_client.models.generate_content(
                        model="gemini-2.5-flash",
                        contents=prompt
                    )
                    result_text = response.text.strip()
                    
                    # Extract JSON from markdown code blocks if present
                    if '```json' in result_text:
                        result_text = result_text.split('```json')[1].split('```')[0].strip()
                    elif '```' in result_text:
                        result_text = result_text.split('```')[1].split('```')[0].strip()
                    
                    import json
                    result = json.loads(result_text)
                    
                    return {
                        'agrees_with_ml': result.get('agrees', True),
                        'confidence_boost': max(-0.15, min(0.15, result.get('confidence_adjustment', 0.0))),
                        'reasoning': result.get('reasoning', 'LLM validation completed'),
                        'alternative_diagnosis': result.get('alternative_diagnosis')
                    }
                    
                except Exception as gemini_error:
                    self.logger.warning(f"Gemini validation failed: {gemini_error}")
            
            # If all LLMs fail, return neutral validation
            return {
                'agrees_with_ml': True,
                'confidence_boost': 0.0,
                'reasoning': 'LLM validation unavailable, using ML prediction only',
                'alternative_diagnosis': None
            }
            
        except Exception as e:
            self.logger.error(f"LLM validation error: {e}")
            return {
                'agrees_with_ml': True,
                'confidence_boost': 0.0,
                'reasoning': f'Validation error: {str(e)}',
                'alternative_diagnosis': None
            }

