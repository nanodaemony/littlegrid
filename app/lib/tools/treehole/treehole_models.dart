class TreeholePost {
  final int id;
  final String content;
  final String tag;
  final int createdAt;
  final int? replyCount;

  TreeholePost({
    required this.id,
    required this.content,
    required this.tag,
    required this.createdAt,
    this.replyCount,
  });

  factory TreeholePost.fromJson(Map<String, dynamic> json) {
    return TreeholePost(
      id: json['id'] as int,
      content: json['content'] as String,
      tag: json['tag'] as String,
      createdAt: json['createdAt'] as int,
      replyCount: json['replyCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'tag': tag,
      'createdAt': createdAt,
      'replyCount': replyCount,
    };
  }

  TreeholePost copyWith({
    int? id,
    String? content,
    String? tag,
    int? createdAt,
    int? replyCount,
  }) {
    return TreeholePost(
      id: id ?? this.id,
      content: content ?? this.content,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
      replyCount: replyCount ?? this.replyCount,
    );
  }
}

class TreeholeReply {
  final int id;
  final int postId;
  final String content;
  final int? parentId;
  final int likeCount;
  final bool isLiked;
  final int createdAt;
  final List<TreeholeReply>? children;

  TreeholeReply({
    required this.id,
    required this.postId,
    required this.content,
    this.parentId,
    required this.likeCount,
    required this.isLiked,
    required this.createdAt,
    this.children,
  });

  factory TreeholeReply.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List?;
    return TreeholeReply(
      id: json['id'] as int,
      postId: json['postId'] as int,
      content: json['content'] as String,
      parentId: json['parentId'] as int?,
      likeCount: json['likeCount'] as int,
      isLiked: json['isLiked'] as bool? ?? false,
      createdAt: json['createdAt'] as int,
      children: childrenJson
          ?.map((e) => TreeholeReply.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'content': content,
      'parentId': parentId,
      'likeCount': likeCount,
      'isLiked': isLiked,
      'createdAt': createdAt,
      'children': children?.map((e) => e.toJson()).toList(),
    };
  }

  TreeholeReply copyWith({
    int? id,
    int? postId,
    String? content,
    int? parentId,
    int? likeCount,
    bool? isLiked,
    int? createdAt,
    List<TreeholeReply>? children,
  }) {
    return TreeholeReply(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      children: children ?? this.children,
    );
  }
}

class PostDetail {
  final TreeholePost post;
  final List<TreeholeReply> replies;

  PostDetail({
    required this.post,
    required this.replies,
  });

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    final repliesJson = json['replies'] as List?;
    return PostDetail(
      post: TreeholePost.fromJson(json['post'] as Map<String, dynamic>),
      replies: repliesJson
              ?.map((e) => TreeholeReply.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post': post.toJson(),
      'replies': replies.map((e) => e.toJson()).toList(),
    };
  }
}

class LikeResult {
  final int id;
  final int likeCount;

  LikeResult({
    required this.id,
    required this.likeCount,
  });

  factory LikeResult.fromJson(Map<String, dynamic> json) {
    return LikeResult(
      id: json['id'] as int,
      likeCount: json['likeCount'] as int,
    );
  }
}

/// 标签常量
class TreeholeTags {
  static const String all = '全部';
  static const String worry = '烦恼';
  static const String secret = '秘密';
  static const String help = '求助';
  static const String share = '分享';
  static const String other = '其他';

  static const List<String> allTags = [all, worry, secret, help, share, other];
  static const List<String> selectableTags = [worry, secret, help, share, other];
}
