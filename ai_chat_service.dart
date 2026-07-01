import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_conversation.dart';
import 'ai_service.dart';

class AIChatService {
  final SupabaseClient _client = Supabase.instance.client;
  final AIService _aiService = AIService();
  
  // Send message to AI and save conversation
  Future<AIConversation> sendMessage(
    String userMessage, {
    List<Map<String, dynamic>>? recentReadings,
    List<Map<String, dynamic>>? medications,
    Map<String, dynamic>? adherenceStats,
  }) async {
    final userId = _client.auth.currentUser!.id;
    
    // Get AI response with patient context
    final aiResponse = await _aiService.getChatResponse(
      userMessage,
      recentReadings: recentReadings,
      medications: medications,
      adherenceStats: adherenceStats,
    );
    
    // Save to database
    final data = {
      'user_id': userId,
      'user_message': userMessage,
      'ai_response': aiResponse,
      'conversation_date': DateTime.now().toIso8601String().split('T')[0],
    };
    
    final response = await _client
        .from('ai_conversations')
        .insert(data)
        .select()
        .single();
    
    return AIConversation.fromJson(response);
  }
  
  // Get all conversations
  Future<List<AIConversation>> getConversations({int limit = 100}) async {
    final userId = _client.auth.currentUser!.id;
    
    final response = await _client
        .from('ai_conversations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    
    return (response as List)
        .map((json) => AIConversation.fromJson(json))
        .toList();
  }
  
  // Get conversations grouped by date
  Future<List<ConversationsByDate>> getConversationsByDate() async {
    final conversations = await getConversations();
    
    // Group by date
    final Map<String, List<AIConversation>> grouped = {};
    
    for (final conv in conversations) {
      final dateKey = conv.conversationDate.toIso8601String().split('T')[0];
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(conv);
    }
    
    // Convert to list
    return grouped.entries.map((entry) {
      return ConversationsByDate(
        date: DateTime.parse(entry.key),
        conversations: entry.value,
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
  }
  
  // Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    await _client
        .from('ai_conversations')
        .delete()
        .eq('id', conversationId);
  }
  
  // Delete all conversations for a date
  Future<void> deleteConversationsForDate(DateTime date) async {
    final userId = _client.auth.currentUser!.id;
    final dateStr = date.toIso8601String().split('T')[0];
    
    await _client
        .from('ai_conversations')
        .delete()
        .eq('user_id', userId)
        .eq('conversation_date', dateStr);
  }
}
