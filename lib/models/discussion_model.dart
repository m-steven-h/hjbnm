// lib/models/discussion_model.dart

class DiscussionModel {
  final String id;
  final String userId; // ✅ جديد: ID فريد للمستخدم
  final String userName;
  final String userImage;
  final String content;
  final DateTime? createdAt;
  final bool isFromUser;

  DiscussionModel({
    required this.id,
    required this.userId, // ✅ جديد
    required this.userName,
    required this.userImage,
    required this.content,
    this.createdAt,
    this.isFromUser = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId, // ✅ جديد
      'userName': userName,
      'userImage': userImage,
      'content': content,
      'createdAt': createdAt?.toIso8601String(),
      'isFromUser': isFromUser,
    };
  }

  factory DiscussionModel.fromMap(Map<String, dynamic> map) {
    return DiscussionModel(
      id: map['id'],
      userId: map['userId'] ?? '', // ✅ جديد
      userName: map['userName'],
      userImage: map['userImage'],
      content: map['content'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      isFromUser: map['isFromUser'] ?? false,
    );
  }
}
