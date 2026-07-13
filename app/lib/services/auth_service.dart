import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;

  void _syncApiHeaders() {
    ApiService.currentUserRole = _currentUser?.role.name;
    ApiService.currentUsername = _currentUser?.username;
  }

  Future<void> init() async {
    // Sempre começa sem autenticação — exibe a tela de login.
    // NÃO tenta re-autenticar automaticamente com credenciais salvas.
    // Isso evita travamentos quando a API não responde e garante
    // que o usuário sempre passe pela tela de login ao abrir o sistema.
    _currentUser = null;
    _syncApiHeaders();
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/pca/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUser = User(
          id: userData['id'],
          username: userData['username'],
          name: userData['name'],
          role: _mapRole(userData['role']),
          editLocked: userData['edit_locked'] ?? false,
          individualRelease: userData['individual_release'] ?? false,
        );
        
        _syncApiHeaders();
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Erro ao efetuar login: $e');
    }
    
    return false;
  }

  void loginAsGuest() {
    _currentUser = User(
      username: 'guest',
      name: 'Visitante',
      role: UserRole.viewer,
    );
    
    _syncApiHeaders();
    notifyListeners();
  }

  UserRole _mapRole(String roleStr) {
    switch (roleStr) {
      case 'admin': return UserRole.admin;
      case 'editor': return UserRole.editor;
      case 'viewer':
      default: return UserRole.viewer;
    }
  }

  void logout() {
    _currentUser = null;
    _syncApiHeaders();
    notifyListeners();
  }
}
