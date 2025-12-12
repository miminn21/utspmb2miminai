from flask import Flask, request, jsonify
from flask_cors import CORS
import google.generativeai as genai
from duckduckgo_search import DDGS
import requests
import re
import math
import sympy
from sympy import symbols, solve, simplify, diff, integrate
from bs4 import BeautifulSoup
import os
import json
import logging
import sys
import time
import ssl
import urllib3
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Disable SSL warnings untuk development
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# API Key Gemini dari .env
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY', '')

# Konfigurasi dari .env
FLASK_DEBUG = os.getenv('FLASK_DEBUG', 'True').lower() == 'true'
ENABLE_SEARCH = os.getenv('ENABLE_SEARCH', 'true').lower() == 'true'
ENABLE_MATH_SOLVER = os.getenv('ENABLE_MATH_SOLVER', 'true').lower() == 'true'
ENABLE_WEB_SCRAPING = os.getenv('ENABLE_WEB_SCRAPING', 'true').lower() == 'true'
AI_MODEL = os.getenv('AI_MODEL', 'gemini-2.0-flash')

logger.info(f"🔑 API Key Status: {'✅ Loaded' if GEMINI_API_KEY else '❌ Not Found'}")

class AdvancedAISystem:
    def __init__(self):
        self.gemini_model = None
        self.search_client = None
        self._initialize_services()
    
    def _initialize_services(self):
        """Initialize semua services dengan error handling yang diperbaiki"""
        # Initialize Gemini AI - GUNAKAN MODEL YANG TERSEDIA
        try:
            if GEMINI_API_KEY and len(GEMINI_API_KEY) > 10:
                genai.configure(api_key=GEMINI_API_KEY)
                
                # Model yang tersedia di API key Anda (dari log)
                available_models_in_your_account = [
                    'models/gemini-2.0-flash',        # Model flash terbaru
                    'models/gemini-2.0-flash-001',    # Model flash stable
                    'models/gemini-flash-latest',     # Model flash latest
                    'models/gemini-2.0-flash-lite',   # Model flash lite
                    'models/gemini-2.0-flash-lite-001', # Model flash lite stable
                    'models/gemini-flash-lite-latest', # Model flash lite latest
                    'models/gemini-pro-latest',       # Model pro latest
                ]
                
                # Coba model yang tersedia
                for model_name in available_models_in_your_account:
                    try:
                        self.gemini_model = genai.GenerativeModel(model_name)
                        # Test connection sederhana
                        test_response = self.gemini_model.generate_content("Hello", 
                            generation_config=genai.types.GenerationConfig(max_output_tokens=100))
                        logger.info(f"✅ Gemini AI Initialized Successfully with: {model_name}")
                        break
                    except Exception as model_error:
                        logger.warning(f"❌ Model {model_name} failed: {str(model_error)[:100]}...")
                        continue
                
                if not self.gemini_model:
                    logger.error("❌ No compatible Gemini model found")
                    logger.info("💡 Using enhanced search and math solver only")
                        
            else:
                logger.warning("❌ Gemini API Key tidak valid")
        except Exception as e:
            logger.error(f"❌ Gemini AI Initialization Failed: {e}")
            self.gemini_model = None
        
        # Initialize DuckDuckGo Search
        try:
            self.search_client = DDGS(timeout=10)
            logger.info("✅ DuckDuckGo Search Initialized Successfully")
        except Exception as e:
            logger.error(f"❌ DuckDuckGo Search Initialization Failed: {e}")
            self.search_client = None
    
    def enhanced_search_duckduckgo(self, query, max_results=8):
        """Pencarian real-time yang lebih komprehensif dari DuckDuckGo"""
        if not self.search_client:
            return []
        try:
            # Multiple search types dengan error handling individual
            all_results = []
            
            try:
                text_results = list(self.search_client.text(query, max_results=max_results))
                for r in text_results:
                    all_results.append({
                        "type": "web",
                        "title": r.get("title", "No Title"),
                        "url": r.get("href", "#"),
                        "snippet": r.get("body", "No description")[:250] + "...",
                        "relevance": self._calculate_relevance(query, r.get("title", "") + " " + r.get("body", ""))
                    })
            except Exception as text_error:
                logger.warning(f"⚠️ Text search failed: {text_error}")
            
            try:
                news_results = list(self.search_client.news(query, max_results=3))
                for r in news_results:
                    all_results.append({
                        "type": "news",
                        "title": r.get("title", "No Title"),
                        "url": r.get("url", "#"),
                        "snippet": r.get("body", "No description")[:200] + "...",
                        "relevance": self._calculate_relevance(query, r.get("title", "") + " " + r.get("body", ""))
                    })
            except Exception as news_error:
                logger.warning(f"⚠️ News search failed: {news_error}")
            
            # Sort by relevance
            all_results.sort(key=lambda x: x["relevance"], reverse=True)
            return all_results[:max_results]
            
        except Exception as e:
            logger.error(f"❌ Enhanced search error: {e}")
            return []
    
    def _calculate_relevance(self, query, text):
        """Hitung relevansi antara query dan teks"""
        query_words = set(query.lower().split())
        text_words = set(text.lower().split())
        common_words = query_words.intersection(text_words)
        return len(common_words) / len(query_words) if query_words else 0
    
    def solve_math_problem(self, problem):
        """Solver matematika yang powerful"""
        try:
            problem_lower = problem.lower()
            
            # Basic arithmetic
            if any(op in problem for op in ['+', '-', '*', '/', '^']):
                # Remove text and keep only math expression
                math_expr = re.sub(r'[^\d+\-*/().^]', '', problem)
                if math_expr:
                    result = eval(math_expr.replace('^', '**'))
                    return f"**Jawaban Matematika:**\n\n`{problem}` = `{result}`"
            
            # Algebra
            if any(word in problem_lower for word in ['x=', 'y=', 'solve', 'persamaan']):
                x = symbols('x')
                y = symbols('y')
                
                # Extract equation
                if '=' in problem:
                    parts = problem.split('=')
                    if len(parts) == 2:
                        left = parts[0].strip()
                        right = parts[1].strip()
                        equation = f"{left} - ({right})"
                        solutions = solve(equation, x)
                        if solutions:
                            return f"**Solusi Persamaan:**\n\n`{problem}`\n\n**x = {solutions}**"
            
            # Calculus
            if any(word in problem_lower for word in ['turunan', 'derivative', 'integral']):
                x = symbols('x')
                if 'turunan' in problem_lower or 'derivative' in problem_lower:
                    # Extract function
                    func_match = re.search(r'[fd]\(x\)\s*=\s*([^,\n]+)', problem)
                    if func_match:
                        func_str = func_match.group(1)
                        derivative = diff(func_str, x)
                        return f"**Turunan:**\n\nf(x) = {func_str}\n\nf'(x) = {derivative}"
                
                if 'integral' in problem_lower:
                    func_match = re.search(r'∫\s*([^dx]+)\s*dx', problem)
                    if func_match:
                        func_str = func_match.group(1)
                        integral = integrate(func_str, x)
                        return f"**Integral:**\n\n∫ {func_str} dx = {integral} + C"
            
            # Geometry
            if any(word in problem_lower for word in ['luas', 'volume', 'keliling', 'segitiga', 'lingkaran']):
                if 'lingkaran' in problem_lower and 'jari' in problem_lower:
                    radius_match = re.search(r'jari[-\s]*jari\s*=\s*(\d+)', problem_lower)
                    if radius_match:
                        r = float(radius_match.group(1))
                        luas = math.pi * r * r
                        keliling = 2 * math.pi * r
                        return f"**Lingkaran (r={r}):**\n\n- Luas = π × r² = {luas:.2f}\n- Keliling = 2 × π × r = {keliling:.2f}"
            
            return None
            
        except Exception as e:
            logger.error(f"Math solver error: {e}")
            return None
    
    def get_web_content(self, url):
        """Ambil konten dari website untuk analisis mendalam"""
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
            
            # Gunakan session dengan SSL verification disabled untuk development
            session = requests.Session()
            session.verify = False
            
            response = session.get(url, headers=headers, timeout=10)
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Ambil konten utama
            title = soup.title.string if soup.title else "No Title"
            
            # Hapus script dan style
            for script in soup(["script", "style"]):
                script.decompose()
            
            text = soup.get_text()
            lines = (line.strip() for line in text.splitlines())
            chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
            content = ' '.join(chunk for chunk in chunks if chunk)
            
            return {
                "title": title,
                "content": content[:1000] + "..." if len(content) > 1000 else content
            }
        except Exception as e:
            return {"title": "Error", "content": f"Could not fetch content: {e}"}
    
    def get_gemini_response(self, prompt, context=""):
        """Dapatkan respons dari Gemini AI"""
        if not self.gemini_model:
            return self.get_fallback_response(prompt, None, [])
        
        try:
            # Enhanced prompt untuk hasil yang lebih baik
            enhanced_prompt = f"""
            Anda adalah asisten AI yang sangat pintar dan membantu. 
            
            CONTEXT/SEARCH RESULTS:
            {context}
            
            USER QUESTION: {prompt}
            
            INSTRUCTIONS:
            1. Berikan jawaban yang akurat dan informatif
            2. Jika ada informasi dari search results, gunakan sebagai referensi
            3. Jika pertanyaan tentang matematika, berikan penjelasan step-by-step
            4. Format jawaban dengan rapi menggunakan Markdown
            5. Untuk konsep kompleks, berikan contoh sederhana
            6. Sertakan sumber referensi jika tersedia
            
            JAWABAN:
            """
            
            # Generate content dengan config yang benar
            response = self.gemini_model.generate_content(
                enhanced_prompt,
                generation_config=genai.types.GenerationConfig(
                    temperature=0.3,
                    max_output_tokens=1500,
                    top_p=0.8,
                )
            )
            return response.text
        except Exception as e:
            logger.error(f"Gemini API error: {e}")
            return self.get_fallback_response(prompt, None, [])
    
    def get_fallback_response(self, question, math_answer, search_results):
        """Generate fallback response tanpa Gemini AI"""
        response = "🤖 **Mimin AI Enhanced**\n\n"
        
        if math_answer:
            response += f"{math_answer}\n\n"
        
        if search_results:
            response += "**🔍 Hasil Penelusuran Terkini:**\n"
            for i, result in enumerate(search_results[:3], 1):
                response += f"{i}. **{result['title']}**\n"
                response += f"   {result['snippet']}\n"
                response += f"   📎 {result['url']}\n\n"
            
            # Tambahkan analisis sederhana berdasarkan hasil pencarian
            response += "**💡 Analisis Berdasarkan Hasil Penelusuran:**\n"
            topics = set()
            for result in search_results[:2]:
                # Extract keywords sederhana
                words = result['title'].lower().split() + result['snippet'].lower().split()
                for word in words:
                    if len(word) > 4 and word not in ['dengan', 'yang', 'dari', 'pada', 'untuk']:
                        topics.add(word)
            
            if topics:
                response += f"Topik terkait: {', '.join(list(topics)[:5])}\n"
        else:
            response += "**📝 Informasi:**\n"
            response += "Fitur pencarian sedang tidak tersedia. "
        
        response += "\n**🧮 Fitur yang Tersedia:**\n"
        response += "• Penyelesaian soal matematika\n• Kalkulator ilmiah\n• Konversi satuan\n• Analisis geometri\n"
        
        return response
    
    def process_question(self, question):
        """Proses pertanyaan dengan kemampuan enhanced"""
        try:
            # Cek apakah ini pertanyaan matematika
            math_keywords = ['hitung', 'berapa', 'matematika', 'kalkulus', 'aljabar', 'geometri', 
                           'turunan', 'integral', 'persamaan', 'segitiga', 'lingkaran', 'volume', 'luas']
            
            is_math_question = any(keyword in question.lower() for keyword in math_keywords)
            
            # Solve math problem first
            math_answer = None
            if is_math_question:
                math_answer = self.solve_math_problem(question)
            
            # Lakukan pencarian web
            search_results = self.enhanced_search_duckduckgo(question)
            
            # Dapatkan jawaban AI atau fallback
            if self.gemini_model:
                # Gabungkan konteks untuk Gemini
                full_context = ""
                if search_results:
                    search_summary = "\n".join([f"• {r['title']}: {r['snippet']}" for r in search_results[:4]])
                    full_context += f"HASIL PENELUSURAN:\n{search_summary}"
                
                ai_response = self.get_gemini_response(question, full_context)
                
                # Jika ada jawaban matematika, tambahkan di awal
                if math_answer:
                    ai_response = f"{math_answer}\n\n---\n\n**Penjelasan Tambahan:**\n{ai_response}"
            else:
                # Gunakan fallback response tanpa Gemini
                ai_response = self.get_fallback_response(question, math_answer, search_results)
            
            return {
                "success": True,
                "question": question,
                "answer": ai_response,
                "search_results": search_results,
                "sources_count": len(search_results),
                "math_solved": math_answer is not None,
                "ai_available": self.gemini_model is not None,
                "search_available": self.search_client is not None,
                "enhanced_features": True
            }
            
        except Exception as e:
            logger.error(f"❌ Process question error: {e}")
            return {
                "success": False,
                "error": str(e),
                "question": question,
                "answer": f"❌ **System Error:** {str(e)}",
                "search_results": []
            }

# Initialize AI System
ai_system = AdvancedAISystem()

@app.route('/api/ask', methods=['POST', 'GET'])
def ask_question():
    """Endpoint untuk menanyakan pertanyaan"""
    try:
        if request.method == 'GET':
            question = request.args.get('question', '').strip()
        else:
            data = request.get_json() or {}
            question = data.get('question', '').strip()
        
        if not question:
            return jsonify({
                "success": False,
                "error": "Pertanyaan tidak boleh kosong"
            }), 400
        
        logger.info(f"📨 Received question: {question}")
        result = ai_system.process_question(question)
        return jsonify(result)
    
    except Exception as e:
        logger.error(f"❌ Endpoint error: {e}")
        return jsonify({
            "success": False,
            "error": f"Server error: {str(e)}"
        }), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "Enhanced AI Assistant",
        "version": "4.0.4",
        "ai_available": ai_system.gemini_model is not None,
        "search_available": ai_system.search_client is not None,
        "features": {
            "math_solver": True,
            "web_search": ai_system.search_client is not None,
            "content_extraction": True,
            "real_time_data": ai_system.search_client is not None,
            "fallback_mode": ai_system.gemini_model is None
        },
        "endpoints": {
            "ask": "/api/ask",
            "health": "/api/health",
            "test": "/api/test"
        }
    })

@app.route('/api/test', methods=['GET'])
def test_api():
    """Test endpoint sederhana"""
    return jsonify({
        "message": "✅ Enhanced Backend berjalan dengan baik!",
        "timestamp": time.strftime('%Y-%m-%d %H:%M:%S'),
        "status": "active",
        "version": "4.0.4",
        "ai_status": "online" if ai_system.gemini_model else "fallback_mode"
    })

@app.route('/')
def home():
    """Home endpoint"""
    ai_status = "✅ Online" if ai_system.gemini_model else "⚠️ Fallback Mode"
    ai_description = "(Full AI Features)" if ai_system.gemini_model else "(Search & Math Only)"
    
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Mimin AI</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }}
            .container {{ max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
            .status {{ padding: 15px; border-radius: 8px; margin: 15px 0; }}
            .success {{ background: #d4edda; color: #155724; border-left: 4px solid #28a745; }}
            .warning {{ background: #fff3cd; color: #856404; border-left: 4px solid #ffc107; }}
            .info {{ background: #d1ecf1; color: #0c5460; border-left: 4px solid #17a2b8; }}
            .feature {{ background: #e7f3ff; padding: 10px; margin: 8px 0; border-radius: 5px; border-left: 4px solid #007bff; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Enhanced AI Assistant v4.0.4</h1>
            <div class="status success">
                <strong>✅ Enhanced Backend Server Active</strong>
                <p>Server berjalan di port 5000 dengan fitur-fitur canggih</p>
            </div>
            
            <h3>🎯 System Status:</h3>
            <div class="status {'success' if ai_system.gemini_model else 'warning'}">
                <strong>🤖 Gemini AI:</strong> {ai_status} {ai_description}
            </div>
            <div class="status {'success' if ai_system.search_client else 'warning'}">
                <strong>🔍 Web Search:</strong> {'✅ Online' if ai_system.search_client else '⚠️ Limited'}
            </div>
            
            <div class="status info">
                <strong>💡 Mode Saat Ini:</strong>
                {'Full AI Assistant dengan Gemini AI' if ai_system.gemini_model else 'Enhanced Search & Math Assistant'}
            </div>
            
            <h3>🎯 Active Features:</h3>
            <div class="feature">
                <strong>🧮 Math Solver</strong> - Aljabar, Kalkulus, Geometri <strong>(✅ Active)</strong>
            </div>
            <div class="feature">
                <strong>🔍 Enhanced Search</strong> - Web + News + Content Extraction <strong>(✅ Active)</strong>
            </div>
            <div class="feature">
                <strong>🌐 Real-time Data</strong> - Informasi terkini dari web <strong>(✅ Active)</strong>
            </div>
            {'<div class="feature"><strong>🤖 AI Assistant</strong> - Gemini AI Integration <strong>(✅ Active)</strong></div>' if ai_system.gemini_model else '<div class="feature"><strong>🤖 AI Assistant</strong> - Fallback Mode <strong>(⚠️ Limited)</strong></div>'}
            
            <h3>Available Endpoints:</h3>
            <ul>
                <li><a href="/api/health">/api/health</a> - Status server & features</li>
                <li><a href="/api/test">/api/test</a> - Test connection</li>
                <li>/api/ask - Enhanced AI Question endpoint (POST/GET)</li>
            </ul>
            
            <p><strong>💡 Tips:</strong> Sistem bisa menyelesaikan soal matematika kompleks dan mencari informasi real-time dari web!</p>
            {'<p><strong>🎉 Bonus:</strong> Full AI capabilities dengan Gemini AI!</p>' if ai_system.gemini_model else '<p><strong>🔧 Note:</strong> Using enhanced search and math features. AI responses limited.</p>'}
        </div>
    </body>
    </html>
    """

if __name__ == '__main__':
    print("🚀 ENHANCED AI Assistant Server Starting...")
    print("📡 URL: http://localhost:5000")
    print("🔗 Health: http://localhost:5000/api/health")
    
    if ai_system.gemini_model:
        print("🤖 Gemini: ✅ Ready (Latest Model)")
    else:
        print("🤖 Gemini: ⚠️ Fallback Mode (Using Search & Math Only)")
    
    print("🔍 Search: ✅ Enhanced Ready") 
    print("🧮 Math Solver: ✅ Active")
    print("🌐 Web Scraping: ✅ Active")
    print("=" * 60)
    
    # Jalankan server
    app.run(host='0.0.0.0', port=5000, debug=True, use_reloader=False)
