import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';

class ButtonDesignPage extends StatelessWidget {
  const ButtonDesignPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('按钮设计'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Filled Buttons
          _buildSectionTitle('填充按钮 (ElevatedButton)'),
          _buildButtonRow([
            ElevatedButton(
              onPressed: () {},
              child: const Text('默认'),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: const Text('Success'),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
              ),
              child: const Text('Warning'),
            ),
          ]),
          _buildButtonRow([
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Error'),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
              ),
              child: const Text('Info'),
            ),
          ]),
          _buildSectionSubtitle('不同大小'),
          _buildButtonRow([
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 56),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('大号'),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 40),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: const Text('中号'),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(60, 32),
                textStyle: const TextStyle(fontSize: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('小号'),
            ),
          ]),
          _buildSectionSubtitle('带图标'),
          _buildButtonRow([
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('添加'),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save),
              label: const Text('保存'),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.delete),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              label: const Text('删除'),
            ),
          ]),
          _buildSectionSubtitle('状态'),
          _buildButtonRow([
            const ElevatedButton(
              onPressed: null,
              child: Text('禁用'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('加载中'),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // Section 2: Outlined Buttons
          _buildSectionTitle('轮廓按钮 (OutlinedButton)'),
          _buildButtonRow([
            OutlinedButton(
              onPressed: () {},
              child: const Text('默认'),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
              ),
              child: const Text('Success'),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
              ),
              child: const Text('Warning'),
            ),
          ]),
          _buildSectionSubtitle('边框粗细'),
          _buildButtonRow([
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(width: 1),
              ),
              child: const Text('细边框'),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(width: 2),
              ),
              child: const Text('中边框'),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(width: 3),
              ),
              child: const Text('粗边框'),
            ),
          ]),
          _buildSectionSubtitle('带图标'),
          _buildButtonRow([
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit),
              label: const Text('编辑'),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share),
              label: const Text('分享'),
            ),
            const OutlinedButton(
              onPressed: null,
              child: Text('禁用'),
            ),
          ]),

          const SizedBox(height: 24),

          // Section 3: Text Buttons
          _buildSectionTitle('文字按钮 (TextButton)'),
          _buildButtonRow([
            TextButton(
              onPressed: () {},
              child: const Text('默认'),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppColors.success,
              ),
              child: const Text('Success'),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Error'),
            ),
          ]),
          _buildSectionSubtitle('带图标'),
          _buildButtonRow([
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.link),
              label: const Text('链接'),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.info_outline),
              label: const Text('详情'),
            ),
            const TextButton(
              onPressed: null,
              child: Text('禁用'),
            ),
          ]),

          const SizedBox(height: 24),

          // Section 4: Icon Buttons
          _buildSectionTitle('图标按钮 (IconButton)'),
          _buildButtonRow([
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.favorite_border),
              tooltip: '喜欢',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.bookmark_border),
              color: AppColors.primary,
              tooltip: '收藏',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.share),
              color: AppColors.success,
              tooltip: '分享',
            ),
          ]),
          _buildSectionSubtitle('不同大小'),
          _buildButtonRow([
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.star),
              iconSize: 32,
              color: AppColors.warning,
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.star),
              iconSize: 24,
              color: AppColors.warning,
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.star),
              iconSize: 16,
              color: AppColors.warning,
            ),
          ]),
          _buildSectionSubtitle('填充样式'),
          _buildButtonRow([
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.home),
                color: AppColors.primary,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.home),
                color: Colors.white,
              ),
            ),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
              ),
              child: const Icon(Icons.add),
            ),
          ]),

          const SizedBox(height: 24),

          // Section 5: Floating Action Buttons
          _buildSectionTitle('浮动操作按钮 (FAB)'),
          _buildButtonRow([
            FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            FloatingActionButton.small(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('添加'),
            ),
          ]),
          _buildSectionSubtitle('不同颜色'),
          _buildButtonRow([
            FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.success,
              child: const Icon(Icons.check),
            ),
            FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.warning,
              child: const Icon(Icons.edit),
            ),
            FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.error,
              child: const Icon(Icons.delete),
            ),
          ]),

          const SizedBox(height: 24),

          // Section 6: Other Buttons
          _buildSectionTitle('其他按钮'),
          _buildSectionSubtitle('SegmentedButton'),
          Center(
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('选项1')),
                ButtonSegment(value: 2, label: Text('选项2')),
                ButtonSegment(value: 3, label: Text('选项3')),
              ],
              selected: const {1},
              onSelectionChanged: (Set<int> newSelection) {},
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionSubtitle('ToggleButtons'),
          Center(
            child: ToggleButtons(
              isSelected: const [true, false, false],
              onPressed: (int index) {},
              children: const [
                Icon(Icons.format_bold),
                Icon(Icons.format_italic),
                Icon(Icons.format_underlined),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionSubtitle('DropdownButton'),
          Center(
            child: DropdownButton<String>(
              value: '选项1',
              items: const [
                DropdownMenuItem(value: '选项1', child: Text('选项1')),
                DropdownMenuItem(value: '选项2', child: Text('选项2')),
                DropdownMenuItem(value: '选项3', child: Text('选项3')),
              ],
              onChanged: (String? value) {},
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSectionSubtitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<Widget> buttons) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: buttons,
    );
  }
}
