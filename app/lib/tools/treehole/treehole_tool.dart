import 'package:flutter/material.dart';
import '../../core/services/tool_registry.dart';
import 'treehole_page.dart';

class TreeholeTool implements ToolModule {
  @override
  String get id => 'treehole';

  @override
  String get name => '树洞';

  @override
  String get version => '1.0.0';

  @override
  IconData get icon => Icons.psychology;

  @override
  ToolCategory get category => ToolCategory.life;

  @override
  int get gridSize => 1;

  @override
  Widget buildPage(BuildContext context) => const TreeholePage();

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
