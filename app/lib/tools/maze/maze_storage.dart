import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import 'maze_models.dart';

/// 迷宫本地存储
class MazeStorage {
  static const String _currentStateKey = 'maze_current_state';
  static const String _bestRecordsKey = 'maze_best_records';
  static const String _selectedThemeKey = 'maze_selected_theme';

  /// 保存当前游戏状态
  Future<void> saveState(MazeSaveState state) async {
    try {
      final json = state.toJson();
      await StorageService.setString(_currentStateKey, jsonEncode(json));
    } catch (e) {
      debugPrint('Save maze state failed: $e');
    }
  }

  /// 加载当前游戏状态
  Future<MazeSaveState?> loadState() async {
    try {
      final jsonString = await StorageService.getString(_currentStateKey);
      if (jsonString == null) return null;
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return MazeSaveState.fromJson(json);
    } catch (e) {
      debugPrint('Load maze state failed: $e');
      return null;
    }
  }

  /// 清除当前游戏状态
  Future<void> clearState() async {
    try {
      await StorageService.remove(_currentStateKey);
    } catch (e) {
      debugPrint('Clear maze state failed: $e');
    }
  }

  /// 加载最佳记录列表
  Future<List<BestRecord>> loadBestRecords() async {
    try {
      final jsonString = await StorageService.getString(_bestRecordsKey);
      if (jsonString == null) return [];
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => BestRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Load maze best records failed: $e');
      return [];
    }
  }

  /// 获取指定难度的最佳记录
  Future<BestRecord?> getBestRecord(DifficultyLevel level) async {
    final records = await loadBestRecords();
    try {
      return records.firstWhere((r) => r.level == level);
    } catch (e) {
      return null;
    }
  }

  /// 保存最佳记录（如果更好则更新）
  Future<bool> saveRecordIfBetter(Duration time, int size) async {
    final level = DifficultyLevel.forSize(size);
    final records = await loadBestRecords();
    final existingIndex = records.indexWhere((r) => r.level == level);

    if (existingIndex >= 0) {
      if (time < records[existingIndex].bestTime) {
        records[existingIndex] = BestRecord(
          level: level,
          bestTime: time,
          date: DateTime.now(),
        );
        await _saveRecords(records);
        return true;
      }
      return false;
    } else {
      records.add(BestRecord(
        level: level,
        bestTime: time,
        date: DateTime.now(),
      ));
      await _saveRecords(records);
      return true;
    }
  }

  /// 保存记录列表
  Future<void> _saveRecords(List<BestRecord> records) async {
    try {
      final jsonList = records.map((r) => r.toJson()).toList();
      await StorageService.setString(_bestRecordsKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Save maze best records failed: $e');
    }
  }

  /// 加载选中的主题
  Future<MazeTheme> loadTheme() async {
    try {
      final themeName = await StorageService.getString(_selectedThemeKey);
      if (themeName != null) {
        return MazeTheme.values.firstWhere(
          (t) => t.name == themeName,
          orElse: () => MazeTheme.defaultTheme,
        );
      }
    } catch (e) {
      debugPrint('Load maze theme failed: $e');
    }
    return MazeTheme.defaultTheme;
  }

  /// 保存主题
  Future<void> saveTheme(MazeTheme theme) async {
    try {
      await StorageService.setString(_selectedThemeKey, theme.name);
    } catch (e) {
      debugPrint('Save maze theme failed: $e');
    }
  }
}
