import 'package:flutter/material.dart';
import '../../core/services/tool_registry.dart';
import 'game2048_page.dart';

/// 2048 游戏工具
class Game2048Tool implements ToolModule {
  @override
  String get id => 'game2048';

  @override
  String get name => '2048';

  @override
  String get version => '1.0.0';

  @override
  IconData get icon => Icons.apps;

  @override
  ToolCategory get category => ToolCategory.game;

  @override
  int get gridSize => 1;

  @override
  Widget buildPage(BuildContext context) {
    return const Game2048Page();
  }

  @override
  ToolSettings? get settings => null;

  @override
  Future<void> onInit() async {}

  @override
  Future<void> onDispose() async {}

  @override
  void onEnter() {}

  @override
  void onExit() {}
}
