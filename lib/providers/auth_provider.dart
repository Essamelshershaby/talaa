import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _checkAuthState();
  }

  void _checkAuthState() {
    _authService.authStateChanges.listen((user) {
      if (user == null) {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.login(email, password);

    if (result.isSuccess) {
      _currentUser = result.user;
      _setLoading(false);
      return true;
    } else {
      _error = result.errorMessage;
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _currentUser = null;
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
