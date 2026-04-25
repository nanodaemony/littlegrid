import 'package:flutter/material.dart';
import '../core/ui/app_colors.dart';
import 'design/button_design_page.dart';
import 'design/card_design_page.dart';
import 'design/auth_design_page.dart';

class DesignPage extends StatelessWidget {
  const DesignPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设计'),
      ),
      body: ListView(
        children: [
          _buildMenuItem(
            icon: Icons.smart_button,
            title: '按钮设计',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ButtonDesignPage(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.dashboard,
            title: '卡片设计',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CardDesignPage(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: '认证页面设计',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthDesignPage(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.radio_button_unchecked,
            title: '按钮4',
            onTap: () {
              _showComingSoon(context);
            },
          ),
          _buildMenuItem(
            icon: Icons.radio_button_unchecked,
            title: '按钮5',
            onTap: () {
              _showComingSoon(context);
            },
          ),
          _buildMenuItem(
            icon: Icons.radio_button_unchecked,
            title: '按钮6',
            onTap: () {
              _showComingSoon(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('功能开发中'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
