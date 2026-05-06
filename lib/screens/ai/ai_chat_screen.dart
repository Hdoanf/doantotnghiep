import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/health_record.dart';
import '../../services/auth_service.dart';
import '../../services/gemini_service.dart';
import '../../services/firestore_service.dart';
import '../../services/openrouter_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];
  bool _isLoading = false;
  bool _useOpenRouter = false;

  final _gemini = GeminiService();
  final _openRouter = OpenRouterService();
  final _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Welcome message from AI
    _messages.add(
      const _ChatMessage(
        text: 'Chào bạn, tôi là trợ lý y tế số của bạn. Tôi có thể giúp gì cho tình trạng tim mạch hoặc đường huyết của bạn hôm nay?',
        isUser: false,
      ),
    );
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final user = context.read<AuthService>().user;
      List<HealthRecord> records = [];
      if (user != null) {
        records = await _firestore.getRecentHealthRecords(user.uid).first;
      }

      String response;
      if (_useOpenRouter) {
        response = await _openRouter.getChatResponse(records, text);
      } else {
        response = await _gemini.getHealthAdvice(records, text);
      }

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: response, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: 'Xin lỗi, đã xảy ra lỗi: $e',
            isUser: false,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Trợ lý Sức khỏe AI',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          // AI Model toggle
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modelChip('Gemini', !_useOpenRouter),
                _modelChip('Router', _useOpenRouter),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0) + 1, // +1 for Welcome Header
              itemBuilder: (context, index) {
                if (index == 0) return _buildWelcomeHeader();
                
                final messageIndex = index - 1;
                if (messageIndex == _messages.length) return _typingIndicator();
                
                return _messageBubble(_messages[messageIndex]);
              },
            ),
          ),
          _buildBottomInputArea(),
        ],
      ),
    );
  }

  Widget _modelChip(String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _useOpenRouter = label == 'Router'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.mutedTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 32,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Trợ lý Sức khỏe AI',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sẵn sàng hỗ trợ bạn theo dõi và phân tích\ncác chỉ số tim mạch và tiểu đường.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: AppTheme.mutedTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(_ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryColor : AppTheme.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? AppTheme.primaryColor.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isUser
                    ? null
                    : Border.all(
                        color: AppTheme.borderColor.withValues(alpha: 0.5),
                      ),
              ),
              child: isUser
                  ? Text(
                      message.text,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    )
                  : MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontFamily: 'Manrope',
                          color: AppTheme.textColor,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        strong: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor,
                        ),
                        h1: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textColor,
                        ),
                        h2: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor,
                        ),
                        listBullet: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 15,
                        ),
                        code: TextStyle(
                          backgroundColor: AppTheme.backgroundColor,
                          color: AppTheme.primaryDarkColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: AppTheme.borderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(1),
                const SizedBox(width: 4),
                _dot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: value),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: AppTheme.borderColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Quick Suggestions
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  _suggestionChip('Giải thích chỉ số HbA1c', Icons.show_chart),
                  const SizedBox(width: 8),
                  _suggestionChip('Lời khuyên huyết áp cao', Icons.favorite),
                  const SizedBox(width: 8),
                  _suggestionChip('Chế độ ăn cho tiểu đường', Icons.restaurant),
                ],
              ),
            ),
            // Input Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Nhập câu hỏi sức khỏe...',
                          hintStyle: TextStyle(
                            fontFamily: 'Manrope',
                            color: AppTheme.mutedTextColor,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: _isLoading ? null : _sendMessage,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _isLoading
                                ? AppTheme.mutedTextColor
                                : AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String text, IconData icon) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.textColor),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: AppTheme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({
    required this.text,
    required this.isUser,
  });
}
