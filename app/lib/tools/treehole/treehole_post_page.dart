import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';
import 'treehole_models.dart';
import 'treehole_service.dart';

/// 发布树洞页
class TreeholePostPage extends StatefulWidget {
  const TreeholePostPage({super.key});

  @override
  State<TreeholePostPage> createState() => _TreeholePostPageState();
}

class _TreeholePostPageState extends State<TreeholePostPage> {
  final _textController = TextEditingController();
  String _selectedTag = TreeholeTags.selectableTags.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  int get _currentLength => _textController.text.length;
  bool get _canSubmit => _textController.text.isNotEmpty && _currentLength <= 500;

  Future<void> _onSubmit() async {
    if (!_canSubmit || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await TreeholeService.createPost(
        _textController.text,
        _selectedTag,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发布成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('说点什么'),
        actions: [
          TextButton(
            onPressed: _canSubmit && !_isSubmitting ? _onSubmit : null,
            child: const Text('发布'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _textController,
                    autofocus: true,
                    maxLines: null,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: '写下你的秘密或烦恼...',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '选择标签',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TreeholeTags.selectableTags.map((tag) {
                    final isSelected = tag == _selectedTag;
                    return ChoiceChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTag = tag;
                          });
                        }
                      },
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$_currentLength/500',
                    style: TextStyle(
                      fontSize: 12,
                      color: _currentLength > 500
                          ? AppColors.error
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
