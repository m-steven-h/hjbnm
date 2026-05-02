// lib/models/question_model.dart

class ReplyModel {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;
  final List<String> likedBy;

  ReplyModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.likedBy = const [],
  });

  int get likesCount => likedBy.length;
  bool isLikedBy(String userId) => likedBy.contains(userId);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'likedBy': likedBy,
    };
  }

  factory ReplyModel.fromMap(Map<String, dynamic> map) {
    return ReplyModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'مستخدم',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }

  // ✅ نسخة محدثة من الرد
  ReplyModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? content,
    DateTime? createdAt,
    List<String>? likedBy,
  }) {
    return ReplyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}

class QuestionModel {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String content;
  final DateTime createdAt;
  final List<String> likedBy;
  final List<ReplyModel> replies;

  QuestionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.content,
    required this.createdAt,
    this.likedBy = const [],
    this.replies = const [],
  });

  int get likesCount => likedBy.length;
  int get repliesCount => replies.length;
  bool isLikedBy(String userId) => likedBy.contains(userId);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'likedBy': likedBy,
      'replies': replies.map((r) => r.toMap()).toList(),
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'مستخدم',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      likedBy: List<String>.from(map['likedBy'] ?? []),
      replies: (map['replies'] as List?)
              ?.map((r) => ReplyModel.fromMap(r))
              .toList() ??
          [],
    );
  }

  // ✅ نسخة محدثة من السؤال
  QuestionModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? title,
    String? content,
    DateTime? createdAt,
    List<String>? likedBy,
    List<ReplyModel>? replies,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likedBy: likedBy ?? this.likedBy,
      replies: replies ?? this.replies,
    );
  }
}
