import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/backend_client.dart';
import '../models/question.dart';
import '../models/tech_stack.dart';
import '../models/user_progress.dart';

enum AppThemeStyle {
  blue('蓝色'),
  purple('紫色'),
  orange('橙色'),
  dark('暗色');

  const AppThemeStyle(this.label);

  final String label;

  static AppThemeStyle fromJson(String? value) {
    return AppThemeStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => AppThemeStyle.blue,
    );
  }
}

class AppController extends ChangeNotifier {
  AppController({BackendClient? backendClient})
      : _backendClient = backendClient;

  static const _progressKey = 'android_interview_bank.progress';
  static const _themeKey = 'android_interview_bank.theme';
  static const _techStackKey = 'android_interview_bank.tech_stack';
  static const _clientIdKey = 'android_interview_bank.client_id';

  final BackendClient? _backendClient;

  UserProgress _progress = const UserProgress();
  AppThemeStyle _themeStyle = AppThemeStyle.blue;
  SelectedTechStack? _selectedTechStack;
  String _clientId = '';
  bool _isLoaded = false;

  UserProgress get progress => _progress;
  AppThemeStyle get themeStyle => _themeStyle;
  SelectedTechStack? get selectedTechStack => _selectedTechStack;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawProgress = preferences.getString(_progressKey);
    if (rawProgress != null && rawProgress.isNotEmpty) {
      _progress = UserProgress.fromJson(
        Map<String, Object?>.from(jsonDecode(rawProgress) as Map),
      );
    }
    _themeStyle = AppThemeStyle.fromJson(preferences.getString(_themeKey));
    _selectedTechStack = SelectedTechStack.fromStorage(
      preferences.getString(_techStackKey),
    );
    _clientId = preferences.getString(_clientIdKey) ?? '';
    if (_clientId.isEmpty) {
      _clientId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      await preferences.setString(_clientIdKey, _clientId);
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> toggleFavorite(String questionId) async {
    final current = _progress.stateFor(questionId).isFavorite;
    _progress = _progress.setFavorite(questionId, !current);
    await _saveProgress();
    notifyListeners();
  }

  Future<void> setReviewStatus(String questionId, ReviewStatus status) async {
    _progress = _progress.setStatus(questionId, status);
    await _saveProgress();
    notifyListeners();
  }

  Future<void> setThemeStyle(AppThemeStyle style) async {
    _themeStyle = style;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, style.name);
    notifyListeners();
  }

  Future<void> setSelectedTechStack(SelectedTechStack stack) async {
    _selectedTechStack = stack;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_techStackKey, stack.storageValue);
    await _syncProgress();
    notifyListeners();
  }

  Future<void> resetProgress() async {
    _progress = const UserProgress();
    await _saveProgress();
    notifyListeners();
  }

  String exportProgress() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(_progress.toJson());
  }

  Future<void> _saveProgress() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_progressKey, jsonEncode(_progress.toJson()));
    await _syncProgress();
  }

  Future<void> _syncProgress() async {
    final backendClient = _backendClient;
    if (backendClient == null || _clientId.isEmpty) {
      return;
    }
    try {
      await backendClient.syncProgress(
        clientId: _clientId,
        progress: _progress,
        selectedTechStack: _selectedTechStack,
      );
    } catch (_) {
      // Progress is still safely stored locally; sync retries on the next change.
    }
  }
}
