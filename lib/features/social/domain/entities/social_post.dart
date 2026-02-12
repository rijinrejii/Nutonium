class SocialPost {
  final String id;
  final String userName;
  final String? userAvatar;
  final String content;
  final String? imageUrl;
  final int likes;
  final int comments;
  final bool isLiked;
  final DateTime timestamp;

  SocialPost({
    required this.id,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.isLiked,
    required this.timestamp,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    return SocialPost(
      id: json['id'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      likes: json['likes'] as int,
      comments: json['comments'] as int,
      isLiked: json['isLiked'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'imageUrl': imageUrl,
      'likes': likes,
      'comments': comments,
      'isLiked': isLiked,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  SocialPost copyWith({
    String? id,
    String? userName,
    String? userAvatar,
    String? content,
    String? imageUrl,
    int? likes,
    int? comments,
    bool? isLiked,
    DateTime? timestamp,
  }) {
    return SocialPost(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}