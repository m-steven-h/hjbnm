// lib/models/discussion_model.dart

class DiscussionModel {
  final String id;
  final String userName;
  final String userImage;
  final String content;
  final DateTime? createdAt; // علامة استفهام يعني اختياري
  final bool isFromUser;

  DiscussionModel({
    required this.id,
    required this.userName,
    required this.userImage,
    required this.content,
    this.createdAt, // اختياري
    this.isFromUser = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      userName: map['userName'],
      userImage: map['userImage'],
      content: map['content'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null, // لو مش موجود يبقى null
      isFromUser: map['isFromUser'] ?? false,
    );
  }
}
