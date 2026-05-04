import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/gemini_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/health_record.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _geminiService = GeminiService();
  final _firestoreService = FirestoreService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  List<HealthRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final user = context.read<AuthService>().user;
    if (user != null) {
      _firestoreService.getRecentHealthRecords(user.uid, limit: 8).first.then((
        records,
      ) {
        if (mounted) setState(() => _history = records);
      });
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          role: MessageRole.user,
          timestamp: DateTime.now(),
        ),
      );
      _controller.clear();
      _isLoading = true;
    });

    try {
      final response = await _geminiService.getHealthAdvice(_history, text);
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: response,
              role: MessageRole.model,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyAiError(e))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyAiError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('429') || message.contains('quota')) {
      return 'AI đang hết quota tạm thời. Chờ một lúc rồi thử lại.';
    }
    return 'Lỗi AI: $message';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
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
      appBar: AppBar(title: const Text('AI Tư vấn sức khỏe')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _emptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _messageBubble(_messages[index]);
                    },
                  ),
          ),
          if (_isLoading) _loadingRow(),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.borderColor.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accentLightColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Hỏi nhanh về sức khỏe',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'AI sẽ trả lời ngắn gọn dựa trên các chỉ số gần đây.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _promptChip('Huyết áp của tôi có ổn không?'),
                  _promptChip('Tôi nên theo dõi chỉ số nào?'),
                  _promptChip('Tóm tắt sức khỏe gần đây'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promptChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _controller.text = text;
        _sendMessage();
      },
      backgroundColor: AppTheme.accentLightColor,
      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      labelStyle: const TextStyle(
        color: AppTheme.primaryColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _messageBubble(ChatMessage msg) {
    final isUser = msg.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUser ? AppTheme.primaryColor : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: isUser
                ? null
                : Border.all(
                    color: AppTheme.borderColor.withValues(alpha: 0.45),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.health_and_safety_outlined,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'HF AI',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isUser)
                Text(
                  msg.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.45,
                  ),
                )
              else
                ..._aiMessageBlocks(msg.text),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _aiMessageBlocks(String text) {
    final lines = _normalizeAiLines(text);

    return lines.map((line) {
      final cleanLine = _cleanMarkdown(line);
      final isHeading = _isHeading(line, cleanLine);
      final isBullet = _isBullet(line);

      if (isHeading) {
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            cleanLine,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        );
      }

      if (isBullet) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 8, right: 8),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(child: _aiBodyText(cleanLine)),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _aiBodyText(cleanLine),
      );
    }).toList();
  }

  List<String> _normalizeAiLines(String text) {
    final rawLines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final lines = <String>[];

    for (final line in rawLines) {
      final cleanLine = _cleanMarkdown(line);
      if (lines.isNotEmpty &&
          !_isHeading(line, cleanLine) &&
          !_isBullet(line) &&
          !_isHeading(lines.last, _cleanMarkdown(lines.last)) &&
          !_isBullet(lines.last)) {
        lines[lines.length - 1] = '${lines.last} $line';
      } else {
        lines.add(line);
      }
    }

    return lines;
  }

  Widget _aiBodyText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.secondaryTextColor,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  bool _isHeading(String rawLine, String cleanLine) {
    if (rawLine.startsWith('#')) return true;
    if (RegExp(r'^\d+\.\s').hasMatch(rawLine)) return true;
    return [
      'Nhận định chính',
      'Giải thích chi tiết',
      'Các bước nên làm',
      'Khi nào cần đi khám',
      'Tổng quan',
      'Điểm cần theo dõi',
      'Gợi ý',
    ].any((heading) => cleanLine.startsWith(heading));
  }

  bool _isBullet(String rawLine) {
    return rawLine.startsWith('- ') ||
        rawLine.startsWith('* ') ||
        rawLine.startsWith('• ');
  }

  String _cleanMarkdown(String line) {
    return line
        .replaceFirst(RegExp(r'^#{1,6}\s*'), '')
        .replaceFirst(RegExp(r'^\d+\.\s*'), '')
        .replaceFirst(RegExp(r'^[-*•]\s*'), '')
        .replaceAll('**', '')
        .replaceAll('__', '')
        .trim();
  }

  Widget _loadingRow() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'AI đang phân tích...',
            style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(
            top: BorderSide(
              color: AppTheme.borderColor.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Hỏi AI về sức khỏe...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Gửi',
              onPressed: _isLoading ? null : _sendMessage,
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.borderColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
