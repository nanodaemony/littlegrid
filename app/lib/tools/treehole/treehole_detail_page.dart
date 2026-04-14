import 'package:flutter/material.dart';
import '../../core/ui/app_colors.dart';
import 'treehole_models.dart';
import 'treehole_service.dart';
import 'widgets/treehole_card.dart';
import 'widgets/reply_item.dart';

/// 树洞详情页
class TreeholeDetailPage extends StatefulWidget {
  final int postId;

  const TreeholeDetailPage({super.key, required this.postId});

  @override
  State<TreeholeDetailPage> createState() => _TreeholeDetailPageState();
}

class _TreeholeDetailPageState extends State<TreeholeDetailPage> {
  PostDetail? _detail;
  bool _isLoading = false;
  final _replyController = TextEditingController();
  int? _replyingTo;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final detail = await TreeholeService.getPostDetail(widget.postId);
      if (mounted) {
        setState(() {
          _detail = detail;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onSubmitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    try {
      await TreeholeService.createReply(
        widget.postId,
        content,
        parentId: _replyingTo,
      );

      _replyController.clear();
      setState(() {
        _replyingTo = null;
      });
      _loadDetail();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('回复成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('回复失败: $e')),
        );
      }
    }
  }

  Future<void> _onLikeReply(TreeholeReply reply) async {
    try {
      if (reply.isLiked) {
        await TreeholeService.unlikeReply(reply.id);
      } else {
        await TreeholeService.likeReply(reply.id);
      }
      _loadDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  void _onReplyTo(TreeholeReply reply) {
    setState(() {
      _replyingTo = reply.id;
    });
    _replyController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('树洞详情'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _detail == null
                    ? const Center(child: Text('加载失败'))
                    : _buildContent(),
          ),
          _buildReplyInput(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TreeholeCard(
            post: _detail!.post,
            showReplyCount: false,
          ),
          const SizedBox(height: 24),
          const Text(
            '回复',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          if (_detail!.replies.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  '还没有回复,来说点什么吧~',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            )
          else
            ..._detail!.replies.map((reply) {
              return ReplyItem(
                reply: reply,
                onLike: () => _onLikeReply(reply),
                onUnlike: () => _onLikeReply(reply),
                onReply: () => _onReplyTo(reply),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
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
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '回复中...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _replyingTo = null;
                        });
                      },
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    maxLines: null,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: '说点温暖的话吧...',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _replyController.text.trim().isEmpty ? null : _onSubmitReply,
                  icon: const Icon(Icons.send),
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
