import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIProvider with ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _chatHistory = [];
  String _errorMessage = '';
  bool _backendConnected = false;

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get chatHistory => _chatHistory;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  bool get backendConnected => _backendConnected;

  // URLuntuk Flutter
  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000'; // Untuk web
    } else {
      // Untuk Android emulator & iOS simulator
      return 'http://10.0.2.2:5000';
    }
  }

  AIProvider() {
    _checkBackendConnection();
  }

  Future<void> _checkBackendConnection() async {
    try {
      print('🔍 Checking backend connection to: $_baseUrl/api/health');

      final response = await http
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _backendConnected = true;
        _errorMessage = '';
        print('✅ Backend connected successfully!');
      } else {
        _backendConnected = false;
        _errorMessage = 'Backend tidak merespon (${response.statusCode})';
        print('❌ Backend response error: ${response.statusCode}');
      }
    } catch (e) {
      _backendConnected = false;
      _errorMessage = 'Tidak dapat terhubung ke backend: $e';
      print('❌ Backend connection error: $e');
    }
    notifyListeners();
  }

  Future<void> askQuestion(String question) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    // Tambah pesan user ke chat history
    _chatHistory.add({
      'question': question,
      'answer': '',
      'searchResults': [],
      'timestamp': DateTime.now(),
      'isUser': true,
      'isLoading': false,
      'isError': false,
    });
    notifyListeners();

    try {
      print('📨 Sending question to: $_baseUrl/api/ask');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ask'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'question': question}),
          )
          .timeout(const Duration(seconds: 60));

      print('📡 Ask response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Ask response success: ${data['success']}');

        if (data['success'] == true) {
          // Add AI response as a new message
          _chatHistory.add({
            'question': question,
            'answer': data['answer'] ?? 'Tidak ada jawaban yang diterima',
            'searchResults': data['search_results'] ?? [],
            'timestamp': DateTime.now(),
            'isUser': false,
            'isLoading': false,
            'isError': false,
            'mathSolved': data['math_solved'] ?? false,
            'enhancedFeatures': data['enhanced_features'] ?? false,
          });
          _backendConnected = true;
          _errorMessage = '';
        } else {
          _errorMessage = data['error'] ?? 'Terjadi kesalahan';
          _chatHistory.add({
            'question': question,
            'answer': '❌ Error: $_errorMessage',
            'searchResults': [],
            'timestamp': DateTime.now(),
            'isUser': false,
            'isLoading': false,
            'isError': true,
          });
        }
      } else {
        _errorMessage = 'HTTP ${response.statusCode}';
        _backendConnected = false;
        _chatHistory.add({
          'question': question,
          'answer': '''
❌ Server Error: $_errorMessage

🔧 TROUBLESHOOTING:
• Pastikan Python server berjalan di port 5000
• Jalankan: python app.py
• Buka browser ke: http://localhost:5000
• Cek apakah backend merespon
          ''',
          'searchResults': [],
          'timestamp': DateTime.now(),
          'isUser': false,
          'isLoading': false,
          'isError': true,
        });
      }
    } catch (e) {
      _errorMessage = e.toString();
      _backendConnected = false;

      String errorDetail = e.toString();
      String solution = '';

      if (errorDetail.contains('Connection refused') ||
          errorDetail.contains('Failed host lookup')) {
        solution = '''
🚨 BACKEND TIDAK TERHUBUNG

SOLUSI:
1. Buka terminal/CMD
2. Masuk ke folder project Python
3. Jalankan: python app.py
4. Tunggu hingga "Server started successfully!"
5. Refresh aplikasi ini

📋 PASTIKAN:
✅ Python server berjalan di port 5000
✅ Tidak ada error di terminal Python
✅ Bisa buka http://localhost:5000 di browser
        ''';
      } else if (errorDetail.contains('timed out')) {
        solution = '⏱️ Timeout - Server terlalu lama merespon';
      } else {
        solution = '❌ Error: $errorDetail';
      }

      _chatHistory.add({
        'question': question,
        'answer': solution,
        'searchResults': [],
        'timestamp': DateTime.now(),
        'isUser': false,
        'isLoading': false,
        'isError': true,
      });

      print('❌ Ask question error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _chatHistory.clear();
    _errorMessage = '';
    notifyListeners();
  }

  void retryConnection() {
    print('🔄 Retrying backend connection...');
    _checkBackendConnection();
  }
}
