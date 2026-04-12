import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/ui/app_colors.dart';
import '../models/user.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/avatar_picker.dart';

class MyInfoPage extends StatefulWidget {
  const MyInfoPage({super.key});

  @override
  State<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends State<MyInfoPage> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nicknameController.text = user?.nickname ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onAvatarTap() async {
    final path = await AvatarPicker.show(context);
    if (path != null && mounted) {
      await context.read<AppProvider>().updateAvatar(path);
    }
  }

  Widget _buildAvatar(String? avatarPath) {
    if (avatarPath == null || AvatarPicker.isDefaultAvatar(avatarPath)) {
      final color = AvatarPicker.getDefaultAvatarColor(avatarPath);
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 50,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: ClipOval(
        child: Image.file(
          File(avatarPath),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              size: 50,
              color: AppColors.primary,
            );
          },
        ),
      ),
    );
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.length < 11) return phone ?? '';
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();

    if (nickname.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('昵称不能为空')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().updateUser(
        nickname: nickname,
        email: email.isNotEmpty ? email : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新成功')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final avatarPath = context.watch<AppProvider>().avatarPath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的信息'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 头像
                Center(
                  child: GestureDetector(
                    onTap: _onAvatarTap,
                    child: Stack(
                      children: [
                        _buildAvatar(avatarPath),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 昵称
                _buildInfoItem(
                  label: '昵称',
                  child: TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      hintText: '请输入昵称',
                      border: InputBorder.none,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),

                const Divider(height: 1),

                // 手机号
                _buildInfoItem(
                  label: '手机号',
                  child: Text(
                    _maskPhone(user?.phone),
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),

                const Divider(height: 1),

                // 邮箱
                _buildInfoItem(
                  label: '邮箱',
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: '请输入邮箱',
                      border: InputBorder.none,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // 保存按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '保存',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}
