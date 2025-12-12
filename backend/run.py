# run.py
import os
import sys
import subprocess
import time
import webbrowser
from threading import Timer

def check_dependencies():
    """Cek dan install dependencies yang diperlukan"""
    required_packages = [
        'flask==2.3.3',
        'flask_cors==4.0.0', 
        'google-generativeai==0.3.2',
        'duckduckgo-search==3.9.4',
        'requests==2.31.0',
        'beautifulsoup4==4.12.2',
        'sympy==1.12',
        'python-dotenv==1.0.0',
        'httpx==0.25.2',
        'urllib3==2.0.7',
        'lxml==4.9.3',
        'cssselect==1.2.0',
        'html5lib==1.1'
    ]
    
    print("📦 Checking and installing dependencies...")
    print("=" * 50)
    
    for package in required_packages:
        package_name = package.split('==')[0]
        try:
            if package_name == 'sqlite3':
                __import__('sqlite3')
                print(f"✅ {package_name} (built-in)")
            else:
                import_name = package_name.replace('-', '_')
                __import__(import_name)
                print(f"✅ {package_name}")
        except ImportError:
            print(f"❌ {package_name} not found. Installing {package}...")
            try:
                # Use quiet install untuk output yang lebih bersih
                subprocess.check_call([sys.executable, '-m', 'pip', 'install', package, '--quiet'])
                print(f"✅ {package} installed successfully")
            except Exception as e:
                print(f"⚠️ Failed to install {package}: {e}")

def check_app_requirements():
    """Cek file requirements.txt dan install jika ada"""
    requirements_file = "requirements.txt"
    if os.path.exists(requirements_file):
        print(f"\n📋 Found {requirements_file}, installing dependencies...")
        try:
            subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-r', requirements_file, '--quiet'])
            print("✅ All requirements installed successfully")
        except Exception as e:
            print(f"⚠️ Failed to install from requirements.txt: {e}")
    else:
        print(f"⚠️ {requirements_file} not found, using individual package installation")

def check_env_file():
    """Cek dan buat file .env jika tidak ada"""
    env_file = ".env"
    if not os.path.exists(env_file):
        print(f"\n🔧 Creating {env_file} file...")
        try:
            with open(env_file, 'w', encoding='utf-8') as f:
                f.write("""# AI Assistant Configuration
GEMINI_API_KEY=

# Server Configuration
FLASK_ENV=development
FLASK_DEBUG=True
PORT=5000
HOST=0.0.0.0

# Feature Flags
ENABLE_SEARCH=true
ENABLE_MATH_SOLVER=true
ENABLE_WEB_SCRAPING=true
ENABLE_AI_CHAT=true

# AI Configuration
AI_MODEL=gemini-2.0-flash
AI_MAX_TOKENS=1500
AI_TEMPERATURE=0.3

# Search Configuration
SEARCH_MAX_RESULTS=8
SEARCH_TIMEOUT=10

# Security
CORS_ORIGINS=*
SSL_VERIFY=false
""")
            print(f"✅ {env_file} created successfully")
        except Exception as e:
            print(f"⚠️ Failed to create {env_file}: {e}")
    else:
        print(f"✅ {env_file} file found")

def validate_environment():
    """Validasi environment setup"""
    print("\n🔍 Validating environment setup...")
    
    # Cek file penting
    essential_files = ['app.py']
    missing_files = []
    
    for file in essential_files:
        if os.path.exists(file):
            print(f"✅ {file} found")
        else:
            print(f"❌ {file} missing")
            missing_files.append(file)
    
    if missing_files:
        print(f"\n⚠️ Missing files: {', '.join(missing_files)}")
        return False
    
    # Cek Python version
    python_version = sys.version_info
    if python_version.major == 3 and python_version.minor >= 8:
        print(f"✅ Python {python_version.major}.{python_version.minor}.{python_version.micro} compatible")
    else:
        print(f"⚠️ Python {python_version.major}.{python_version.minor} detected - Python 3.8+ recommended")
    
    # Cek koneksi internet (opsional)
    try:
        import urllib.request
        urllib.request.urlopen('https://www.google.com', timeout=5)
        print("✅ Internet connection available")
    except:
        print("⚠️ No internet connection - some features may be limited")
    
    return True

def start_server():
    """Jalankan Flask server"""
    print("\n🚀 Starting AI ASSISTANT Server...")
    print("=" * 50)
    
    # Gunakan file app.py
    app_file = "app.py"
    
    if not os.path.exists(app_file):
        print(f"❌ File {app_file} tidak ditemukan!")
        print("📁 Pastikan file app.py ada di direktori yang sama")
        return False
    
    try:
        # Jalankan server Flask
        print(f"🔧 Running: python {app_file}")
        print("⏳ Starting server... (This may take 10-15 seconds)")
        print("💡 Initializing AI services and features...")
        
        process = subprocess.Popen([sys.executable, app_file], 
                                 stdout=subprocess.PIPE, 
                                 stderr=subprocess.PIPE,
                                 text=True,
                                 bufsize=1,
                                 universal_newlines=True)
        
        # Tunggu lebih lama untuk inisialisasi services
        print("\n🔄 Initializing AI Services...")
        for i in range(3):
            time.sleep(3)
            print(f"   {i+1}/3 - Loading AI components...")
        
        # Buka browser otomatis
        def open_browser():
            print("🌐 Opening browser...")
            try:
                webbrowser.open('http://localhost:5000')
                time.sleep(1)
                webbrowser.open('http://localhost:5000/api/health')
                print("✅ Browser opened successfully")
            except Exception as e:
                print(f"⚠️ Could not open browser: {e}")
        
        Timer(2, open_browser).start()
        
        print("\n" + "=" * 60)
        print("🎉 SERVER STARTED SUCCESSFULLY!")
        print("=" * 60)
        print("🌐 Server URL: http://localhost:5000")
        print("🔗 Health Check: http://localhost:5000/api/health")
        print("🔗 Test API: http://localhost:5000/api/test")
        print("🤖 AI Assistant: Ready to accept questions")
        print("\n📋 Available Features:")
        print("   • 🤖 AI Chat dengan Gemini (Free Model)")
        print("   • 🔍 Real-time Web Search")
        print("   • 🧮 Advanced Math Solver")
        print("   • 🌐 Web Content Extraction")
        print("   • 📚 Multi-source Analysis")
        print("\n💡 Try these questions:")
        print("   • 'Hitung 25 × 4 + 100 ÷ 2'")
        print("   • 'Jelaskan apa itu artificial intelligence'")
        print("   • 'Berita terbaru tentang teknologi'")
        print("   • 'Solve x^2 - 5x + 6 = 0'")
        print("\n🛑 Press Ctrl+C to stop the server")
        print("=" * 60)
        
        # Tampilkan output server secara real-time
        try:
            while True:
                output = process.stdout.readline()
                if output == '' and process.poll() is not None:
                    break
                if output:
                    # Filter dan format output
                    line = output.strip()
                    if line and not line.startswith('WARNING: This is a development server'):
                        # Highlight important messages
                        if any(keyword in line for keyword in ['ERROR', 'FAILED', '❌']):
                            print(f"🔴 {line}")
                        elif any(keyword in line for keyword in ['WARNING', '⚠️']):
                            print(f"🟡 {line}")
                        elif any(keyword in line for keyword in ['INFO', '✅', '🔑', '📋']):
                            print(f"🔵 {line}")
                        elif 'Initialized Successfully' in line:
                            print(f"🟢 {line}")
                        else:
                            print(line)
                    
                # Juga capture stderr
                err_output = process.stderr.readline()
                if err_output:
                    err_line = err_output.strip()
                    # Filter pesan error yang umum
                    if (err_line and 
                        "Debugger" not in err_line and 
                        "Debugger PIN" not in err_line and
                        "WARNING: This is a development server" not in err_line and
                        "Running on" not in err_line):
                        print(f"⚠️  {err_line}")
                    
                time.sleep(0.1)
                    
        except KeyboardInterrupt:
            print("\n\n🛑 Shutting down server...")
            print("⏳ Please wait...")
            process.terminate()
            try:
                process.wait(timeout=5)
                print("✅ Server stopped gracefully")
            except subprocess.TimeoutExpired:
                process.kill()
                print("⚠️ Server force stopped")
            return True
            
    except Exception as e:
        print(f"❌ Error starting server: {e}")
        print("\n🔧 Troubleshooting tips:")
        print("1. Pastikan port 5000 tidak sedang digunakan")
        print("2. Cek koneksi internet untuk inisialisasi AI services")
        print("3. Pastikan API key Gemini valid di file .env")
        print("4. Coba jalankan langsung: python app.py")
        print("5. Cek log error di atas untuk detail lebih lanjut")
        return False

def check_port_availability():
    """Cek apakah port 5000 tersedia"""
    import socket
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(('localhost', 5000))
        return True
    except socket.error:
        print("❌ Port 5000 sedang digunakan!")
        print("\n💡 Solusi:")
        print("1. Tutup aplikasi lain yang menggunakan port 5000")
        print("2. Atau ubah port di file app.py:")
        print("   - Edit: app.run(port=5001)")
        print("   - Kemudian akses: http://localhost:5001")
        print("3. Cek proses yang menggunakan port 5000:")
        print("   - Windows: netstat -ano | findstr :5000")
        print("   - Linux/Mac: lsof -i :5000")
        return False

def cleanup_old_processes():
    """Bersihkan proses lama yang mungkin masih berjalan"""
    try:
        import psutil
        current_pid = os.getpid()
        cleaned_count = 0
        
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                if (proc.info['pid'] != current_pid and 
                    proc.info['cmdline'] and 
                    'python' in proc.info['cmdline'][0].lower() and
                    any('app.py' in cmd for cmd in proc.info['cmdline'])):
                    
                    print(f"🔄 Stopping old process PID: {proc.info['pid']}")
                    proc.terminate()
                    proc.wait(timeout=3)
                    cleaned_count += 1
                    
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.TimeoutExpired):
                continue
        
        if cleaned_count > 0:
            print(f"✅ Cleaned {cleaned_count} old processes")
        else:
            print("✅ No old processes found")
                
    except ImportError:
        # psutil tidak tersedia, skip cleanup
        print("⚠️ psutil not available - skipping process cleanup")
        pass

def check_system_resources():
    """Cek resource system yang tersedia"""
    print("\n💻 System Resources Check:")
    try:
        import psutil
        # Memory usage
        memory = psutil.virtual_memory()
        print(f"✅ RAM: {memory.percent}% used ({memory.available // (1024**3)}GB available)")
        
        # CPU usage
        cpu_percent = psutil.cpu_percent(interval=1)
        print(f"✅ CPU: {cpu_percent}% used")
        
        # Disk space
        disk = psutil.disk_usage('.')
        print(f"✅ Disk: {disk.percent}% used ({disk.free // (1024**3)}GB free)")
        
    except ImportError:
        print("⚠️ psutil not available - skipping resource check")
    except Exception as e:
        print(f"⚠️ Resource check failed: {e}")

def main():
    """Main function"""
    print("=" * 60)
    print("🤖 AI ASSISTANT - ENHANCED SERVER STARTER v4.0")
    print("=" * 60)
    
    # Cleanup proses lama
    print("\n🔧 System Preparation...")
    cleanup_old_processes()
    
    # Cek system resources
    check_system_resources()
    
    # Validasi environment
    if not validate_environment():
        print("\n❌ Environment validation failed!")
        sys.exit(1)
    
    # Cek dan buat file .env
    check_env_file()
    
    # Cek ketersediaan port
    if not check_port_availability():
        sys.exit(1)
    
    # Install dependencies
    print("\n📦 Dependencies Setup...")
    check_app_requirements()
    check_dependencies()
    
    print("\n" + "=" * 60)
    print("🎯 STARTING ENHANCED AI ASSISTANT...")
    print("=" * 60)
    
    # Jalankan server
    success = start_server()
    
    if success:
        print("\n" + "=" * 60)
        print("👋 Thank you for using AI Assistant!")
        print("🤖 Powered by Gemini AI + Enhanced Search + Math Solver")
        print("=" * 60)
    else:
        print("\n" + "=" * 60)
        print("❌ Server startup failed!")
        print("🔧 Check the errors above and try again.")
        print("💡 You can also try running directly: python app.py")
        print("=" * 60)
        sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⏹️  Startup cancelled by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)
