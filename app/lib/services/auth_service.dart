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
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    final isGuest = prefs.getBool('isGuest') ?? false;

    if (isGuest) {
      loginAsGuest();
    } else if (username != null && password != null) {
      await login(username, password);
    }
    
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
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUser = User(
          id: userData['id'],
          username: userData['username'],
          name: userData['name'],
          role: _mapRole(userData['role']),
          editLocked: userData['edit_locked'] ?? false,
        );
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('password', password);
        await prefs.setBool('isGuest', false);

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
    
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isGuest', true);
      prefs.remove('username');
      prefs.remove('password');
    });
    
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
    
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('username');
      prefs.remove('password');
      prefs.remove('isGuest');
    });
    
    _syncApiHeaders();
    notifyListeners();
  }
}
