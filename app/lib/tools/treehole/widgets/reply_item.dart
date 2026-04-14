import 'package:flutter/material.dart';
import '../../../core/ui/app_colors.dart';
import '../treehole_models.dart';

/// 回复项组件
class ReplyItem extends StatelessWidget {
  final TreeholeReply reply;
  final VoidCallback? onLike;
  final VoidCallback? onUnlike;
  final VoidCallback? onReply;
  final bool isNested;

  const ReplyItem({
    super.key,
    required this.reply,
    this.onLike,
    this.onUnlike,
    this.onReply,
    this.isNested = false,
  });

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: isNested ? 24 : 0, bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isNested
            ? Border(
                left: BorderSide(
                  color: AppColors.primaryLight,
                  width: 2,
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: isNested ? 12 : 0),
            child: Text(
              reply.content,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(left: isNested ? 12 : 0),
            child: Row(
              children: [
                Text(
                  _formatTime(reply.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 16),
                if (!isNested)
                  InkWell(
                    onTap: onReply,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.reply,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '回复',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!isNested) const SizedBox(width: 16),
                InkWell(
                  onTap: reply.isLiked ? onUnlike : onLike,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        reply.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: reply.isLiked ? AppColors.error : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reply.likeCount.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: reply.isLiked ? AppColors.error : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (reply.children != null && reply.children!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: reply.children!.map((child) {
                  return ReplyItem(
                    reply: child,
                    onLike: onLike,
                    onUnlike: onUnlike,
                    isNested: true,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
