import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/health_data_provider.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
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
    
    // Add welcome message
    _messages.add(ChatMessage(
      text: 'Bună ziua! 👋\n\nSunt asistentul dumneavoastră de sănătate. Vă pot ajuta cu:\n\n'
          '• Întrebări despre glicemie și diabet\n'
          '• Întrebări despre tensiune arterială\n'
          '• Informații despre medicamente\n'
          '• Sfaturi de dietă și stil de viață\n\n'
          'Cu ce vă pot ajuta astăzi?',
      isUser: false,
    ));
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

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();
    _startTalking();

    try {
      final provider = context.read<HealthDataProvider>();
      
      final patientData = {
        'recentReadings': provider.readings.take(10).toList(),
        'medications': provider.medications,
        'adherencePercent': provider.adherenceStats?['adherence_percent'] ?? 0,
      };

      final response = await Supabase.instance.client.functions.invoke(
        'health-assistant',
        body: {
          'message': message,
          'patientData': patientData,
        },
      );

      if (response.status == 200 && response.data != null) {
        final aiResponse = response.data['response'] as String?;
        if (aiResponse != null) {
          setState(() {
            _messages.add(ChatMessage(text: aiResponse, isUser: false));
          });
        }
      } else {
        throw Exception('Failed to get response');
      }
    } catch (e) {
      debugPrint('AI Error: $e');
      setState(() {
        _messages.add(ChatMessage(
          text: 'Îmi pare rău, a apărut o eroare. Vă rog încercați din nou.',
          isUser: false,
          isError: true,
        ));
      });
    } finally {
      _stopTalking();
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _mouthAnimation,
              builder: (context, child) {
                return RobotFace(
                  size: 40,
                  mouthOpenness: _mouthAnimation.value,
                  isThinking: _isLoading,
                );
              },
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Asistent AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  _isLoading ? 'Se gândește...' : 'Online',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1), // Indigo
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF6366F1).withOpacity(0.1), Colors.grey.shade50],
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
          ),
          _buildQuickSuggestions(),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            RobotFace(size: 32, mouthOpenness: 0.3, isThinking: false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? const Color(0xFF6366F1)
                    : message.isError 
                        ? Colors.red.shade50 
                        : Colors.white,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: message.isUser ? const Radius.circular(4) : null,
                  bottomLeft: !message.isUser ? const Radius.circular(4) : null,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.isUser
                  ? Text(message.text, style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.4))
                  : MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                        strong: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        em: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87),
                        listBullet: const TextStyle(fontSize: 16, color: Colors.black87),
                        h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        blockSpacing: 12,
                        listIndent: 20,
                      ),
                      selectable: true,
                    ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _mouthAnimation,
            builder: (context, child) {
              return RobotFace(size: 32, mouthOpenness: _mouthAnimation.value, isThinking: true);
            },
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _buildAnimatedDot(i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 200)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Color.lerp(Colors.grey.shade300, const Color(0xFF6366F1), value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = ['Cum e glicemia mea?', 'Sfaturi pentru tensiune', 'Ce să mănânc?'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(s, style: const TextStyle(fontSize: 14, color: Color(0xFF6366F1))),
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
              side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.3)),
              onPressed: () { _messageController.text = s; _sendMessage(); },
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Scrieți întrebarea...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                style: const TextStyle(fontSize: 16),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: IconButton(
                icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.send, color: Colors.white),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated Robot Face Widget
class RobotFace extends StatelessWidget {
  final double size;
  final double mouthOpenness;
  final bool isThinking;

  const RobotFace({
    super.key,
    required this.size,
    required this.mouthOpenness,
    required this.isThinking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: RobotFacePainter(mouthOpenness: mouthOpenness, isThinking: isThinking),
      ),
    );
  }
}

class RobotFacePainter extends CustomPainter {
  final double mouthOpenness;
  final bool isThinking;

  RobotFacePainter({required this.mouthOpenness, required this.isThinking});

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
    final shinePaint = Paint()..color = Colors.white.withOpacity(0.8);
    final shineRadius = pupilRadius * 0.4;
    canvas.drawCircle(Offset(leftEyeX - pupilRadius * 0.3, eyeY - pupilRadius * 0.3), shineRadius, shinePaint);
    canvas.drawCircle(Offset(rightEyeX - pupilRadius * 0.3, eyeY - pupilRadius * 0.3), shineRadius, shinePaint);
    
    // Smiling mouth - curved arc
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
      smilePath.moveTo(size.width / 2 - mouthWidth / 2, mouthY - size.height * 0.02);
      smilePath.quadraticBezierTo(
        size.width / 2, mouthY + size.height * 0.12,
        size.width / 2 + mouthWidth / 2, mouthY - size.height * 0.02,
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
    final ballPaint = Paint()..color = isThinking ? Colors.yellow : Colors.white;
    canvas.drawCircle(Offset(size.width / 2, -size.height * 0.08), size.width * 0.08, ballPaint);
  }

  @override
  bool shouldRepaint(RobotFacePainter oldDelegate) {
    return oldDelegate.mouthOpenness != mouthOpenness || oldDelegate.isThinking != isThinking;
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  ChatMessage({required this.text, required this.isUser, this.isError = false});
}
