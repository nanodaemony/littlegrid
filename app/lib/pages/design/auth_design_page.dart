import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';
import 'auth_style_a/auth_style_a_page.dart';
import 'auth_style_b/auth_style_b_page.dart';
import 'auth_style_c/auth_style_c_page.dart';

class AuthDesignPage extends StatefulWidget {
  const AuthDesignPage({super.key});

  @override
  State<AuthDesignPage> createState() => _AuthDesignPageState();
}

class _AuthDesignPageState extends State<AuthDesignPage>
    with SingleTickerProviderStateMixin {
  int _selectedStyle = 0;
  late TabController _tabController;

  final _stylePages = const [
    AuthStyleAPage(),
    AuthStyleBPage(),
    AuthStyleCPage(),
  ];

  final _styleLabels = ['风格A', '风格B', '风格C'];
  final _styleDescriptions = ['经典居中卡片', '标签分割线卡片', '分段卡片组合'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('认证页面设计'),
      ),
      body: Column(
        children: [
          // Style selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SegmentedButton<int>(
              segments: List.generate(
                3,
                (i) => ButtonSegment<int>(
                  value: i,
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_styleLabels[i]),
                      Text(
                        _styleDescriptions[i],
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              selected: {_selectedStyle},
              onSelectionChanged: (selected) {
                setState(() => _selectedStyle = selected.first);
              },
            ),
          ),

          // Page type tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textTertiary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: '登录'),
                Tab(text: '注册'),
                Tab(text: '忘记密码'),
              ],
            ),
          ),

          // Page content
          Expanded(
            child: IndexedStack(
              index: _selectedStyle,
              children: _stylePages,
            ),
          ),
        ],
      ),
    );
  }
}
