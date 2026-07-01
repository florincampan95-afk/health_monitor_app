// AI Conversation Model
class AIConversation {
  final String id;
  final String userId;
  final String userMessage;
  final String aiResponse;
  final DateTime conversationDate;
  final DateTime createdAt;
  
  AIConversation({
    required this.id,
    required this.userId,
    required this.userMessage,
    required this.aiResponse,
    required this.conversationDate,
    required this.createdAt,
  });
  
  factory AIConversation.fromJson(Map<String, dynamic> json) {
    return AIConversation(
      id: json['id'],
      userId: json['user_id'],
      userMessage: json['user_message'],
      aiResponse: json['ai_response'],
      conversationDate: DateTime.parse(json['conversation_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_message': userMessage,
      'ai_response': aiResponse,
      'conversation_date': conversationDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Grouped conversations by date
class ConversationsByDate {
  final DateTime date;
  final List<AIConversation> conversations;
  
  ConversationsByDate({
    required this.date,
    required this.conversations,
  });
}
