import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    
    const host = String.fromEnvironment('API_HOST', defaultValue: '10.0.2.2');
    return 'http://$host:8000/api';
  }

  static final Dio _dio = _buildDio();
  static Dio get dio => _dio;

  static Dio _buildDio() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('api_token');

          // DEBUG — lihat token dan URL di terminal Flutter
          if (kDebugMode) {
            print('🌐 [API] ${options.method} ${options.uri}');
          }
          if (kDebugMode) {
            print('🔑 [API] Token: ${token ?? "NULL - TIDAK ADA TOKEN"}');
          }

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Token $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // DEBUG — lihat error detail
          if (kDebugMode) {
            print('❌ [API ERROR] ${error.response?.statusCode} - ${error.requestOptions.uri}');
          }
          if (kDebugMode) {
            print('❌ [API ERROR] Response: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),    );

    return dio;
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
    if (kDebugMode) {
      print('✅ [API] Token disimpan: $token');
    }
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
    if (kDebugMode) {
      print('🗑️ [API] Token dihapus');
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_token');
  }
}