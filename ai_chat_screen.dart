import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/ai_chat_service.dart';
import '../models/ai_conversation.dart';
import '../providers/health_data_provider.dart';
import 'ai_history_screen.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with TickerProviderStateMixin {
  final AIChatService _chatService = AIChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<AIConversation> _todayConversations = [];
  bool _isLoading = false;
  bool _isSending = false;
  
  late AnimationController _mouthController;
  late Animation<double> _mouthAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Mouth animation controller
    _mouthController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _mouthAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _mouthController, curve: Curves.easeInOut),
    );
    
    _loadTodayConversations();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _mouthController.dispose();
    super.dispose();
  }
  
  void _startTalking() {
    _mouthController.repeat(reverse: true);
  }

  void _stopTalking() {
    _mouthController.stop();
    _mouthController.animateTo(0.3);
  }
  
  Future<void> _loadTodayConversations() async {
    setState(() => _isLoading = true);
    
    try {
      final allConversations = await _chatService.getConversations();
      final today = DateTime.now();
      
      _todayConversations = allConversations.where((conv) {
        return conv.conversationDate.year == today.year &&
               conv.conversationDate.month == today.month &&
               conv.conversationDate.day == today.day;
      }).toList();
      
      setState(() => _isLoading = false);
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    }
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;
    
    setState(() => _isSending = true);
    _messageController.clear();
    _startTalking();
    
    try {
      // Get patient data from provider
      final provider = context.read<HealthDataProvider>();
      
      final conversation = await _chatService.sendMessage(
        message,
        recentReadings: provider.readings.take(10).toList(),
        medications: provider.medications,
        adherenceStats: provider.adherenceStats,
      );
      
      setState(() {
        _todayConversations.add(conversation);
        _isSending = false;
      });
      
      _stopTalking();
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      _stopTalking();
      setState(() => _isSending = false);
      print('Error in _sendMessage: $e'); // Debug print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistent AI'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Istoric Conversații',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AIHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _todayConversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Începe o conversație',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Întreabă-mă orice despre sănătatea ta',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _todayConversations.length,
                        itemBuilder: (context, index) {
                          final conv = _todayConversations[index];
                          return Column(
                            children: [
                              _buildUserMessage(conv.userMessage),
                              const SizedBox(height: 8),
                              _buildAIMessage(conv.aiResponse),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
          ),
          
          // Loading indicator when sending
          if (_isSending)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('AI răspunde...'),
                ],
              ),
            ),
          
          // Quick suggestions
          _buildQuickSuggestions(),
          
          // Input field
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Scrie mesajul tău...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isSending,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isSending ? null : _sendMessage,
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(
                    Icons.send,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickSuggestions() {
    final theme = Theme.of(context);
    final suggestions = [
      'Cum e glicemia mea?',
      'Sfaturi pentru tensiune',
      'Ce să mănânc?',
      'Când să iau medicamentele?',
      'Exerciții recomandate',
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withAlpha(77),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Întrebări rapide:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return ActionChip(
                label: Text(
                  suggestion,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.primary,
                  ),
                ),
                backgroundColor: theme.colorScheme.primaryContainer.withAlpha(128),
                side: BorderSide(
                  color: theme.colorScheme.primary.withAlpha(77),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: _isSending ? null : () {
                  _messageController.text = suggestion;
                  _sendMessage();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserMessage(String message) {
    final theme = Theme.of(context);
    
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
  
  Widget _buildAIMessage(String message) {
    final theme = Theme.of(context);
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Animated robot face
          AnimatedBuilder(
            animation: _mouthAnimation,
            builder: (context, child) {
              return _RobotFace(
                size: 32,
                mouthOpenness: _isSending ? _mouthAnimation.value : 0.3,
                isThinking: _isSending,
              );
            },
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: MarkdownBody(
                data: message,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSecondaryContainer,
                    height: 1.5,
                  ),
                  strong: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  em: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  listBullet: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  h1: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  h2: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  h3: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  blockSpacing: 8,
                  listIndent: 16,
                ),
                selectable: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Animated Robot Face Widget
class _RobotFace extends StatelessWidget {
  final double size;
  final double mouthOpenness;
  final bool isThinking;

  const _RobotFace({
    required this.size,
    required this.mouthOpenness,
    required this.isThinking,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(size * 0.3),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _RobotFacePainter(
                  mouthOpenness: mouthOpenness,
                  isThinking: isThinking,
                ),
              ),
            );
  }
}

class _RobotFacePainter extends CustomPainter {
  final double mouthOpenness;
  final bool isThinking;

  _RobotFacePainter({
    required this.mouthOpenness,
    required this.isThinking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    
    // Eyes
    final eyeRadius = size.width * 0.12;
    final eyeY = size.height * 0.38;
    final leftEyeX = size.width * 0.32;
    final rightEyeX = size.width * 0.68;
    
    // Eye whites
    canvas.drawCircle(Offset(leftEyeX, eyeY), eyeRadius, paint);
    canvas.drawCircle(Offset(rightEyeX, eyeY), eyeRadius, paint);
    
    // Pupils
    final pupilPaint = Paint()..color = const Color(0xFF1E1B4B);
    final pupilRadius = eyeRadius * 0.5;
    canvas.drawCircle(Offset(leftEyeX, eyeY), pupilRadius, pupilPaint);
    canvas.drawCircle(Offset(rightEyeX, eyeY), pupilRadius, pupilPaint);
    
    // Eye shine
    final shinePaint = Paint()..color = Colors.white.withAlpha(204);
    final shineRadius = pupilRadius * 0.4;
    canvas.drawCircle(
      Offset(leftEyeX - pupilRadius * 0.3, eyeY - pupilRadius * 0.3),
      shineRadius,
      shinePaint,
    );
    canvas.drawCircle(
      Offset(rightEyeX - pupilRadius * 0.3, eyeY - pupilRadius * 0.3),
      shineRadius,
      shinePaint,
    );
    
    // Mouth - animated
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    
    final mouthY = size.height * 0.65;
    final mouthWidth = size.width * 0.35;
    
    if (isThinking && mouthOpenness > 0.5) {
      // Open mouth when talking (oval)
      final openMouthPaint = Paint()..color = Colors.white;
      final mouthHeight = size.height * 0.1 * mouthOpenness;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, mouthY),
          width: mouthWidth * 0.8,
          height: mouthHeight,
        ),
        openMouthPaint,
      );
    } else {
      // Smile arc
      final smilePath = Path();
      smilePath.moveTo(
        size.width / 2 - mouthWidth / 2,
        mouthY - size.height * 0.02,
      );
      smilePath.quadraticBezierTo(
        size.width / 2,
        mouthY + size.height * 0.12,
        size.width / 2 + mouthWidth / 2,
        mouthY - size.height * 0.02,
      );
      canvas.drawPath(smilePath, mouthPaint);
    }
    
    // Antenna
    final antennaPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.08),
      Offset(size.width / 2, -size.height * 0.05),
      antennaPaint,
    );
    
    // Antenna ball
    final ballPaint = Paint()
      ..color = isThinking ? Colors.yellow : Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, -size.height * 0.08),
      size.width * 0.08,
      ballPaint,
    );
  }

  @override
  bool shouldRepaint(_RobotFacePainter oldDelegate) {
    return oldDelegate.mouthOpenness != mouthOpenness ||
        oldDelegate.isThinking != isThinking;
  }
}
