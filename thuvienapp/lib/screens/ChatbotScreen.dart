import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import để lấy API Key
import 'package:flutter_markdown/flutter_markdown.dart'; // Import để hiển thị text đẹp

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Content> _history = [];
  bool _loading = false;
  bool _isInitSuccess = false; // Biến kiểm tra khởi tạo thành công

  @override
  void initState() {
    super.initState();
    _initializeGemini();
  }

  void _initializeGemini() {
    // Lấy API Key từ biến môi trường đã load ở main.dart
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print("LỖI: Chưa cấu hình GEMINI_API_KEY trong file .env");
      setState(() => _isInitSuccess = false);
      return;
    }

    // Khởi tạo model Gemini
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    _chatSession = _model.startChat(history: _history);
    setState(() => _isInitSuccess = true);
  }

  Future<void> _sendMessage() async {
    final message = _textController.text;
    if (message.isEmpty) return;

    setState(() {
      _history.add(Content.text(message)); // Hiển thị tin nhắn của user ngay lập tức
      _loading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      // Gửi tin nhắn đến Gemini
      final response = await _chatSession.sendMessage(Content.text(message));

      // Gemini trả lời xong, UI sẽ tự cập nhật nhờ ListView đọc _history
      setState(() {
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _loading = false;
        // Hiển thị lỗi nếu mạng hoặc API có vấn đề
        _history.add(Content.model([TextPart("Xin lỗi, tôi đang gặp sự cố kết nối: $e")]));
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    // Nếu chưa cấu hình Key, báo lỗi ngay trên màn hình
    if (!_isInitSuccess) {
      return Scaffold(
        appBar: AppBar(title: const Text("Lỗi Cấu Hình")),
        body: const Center(
          child: Text("Vui lòng thêm GEMINI_API_KEY vào file .env và khởi động lại app."),
        ),
      );
    }

    // Lấy lịch sử chat từ session để hiển thị
    final history = _chatSession.history.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trợ lý Thư Viện AI"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: history.length,
              itemBuilder: (context, index) {
                final content = history[index];
                final isUser = content.role == 'user';
                final parts = content.parts;
                // Xử lý an toàn để lấy text
                final text = parts.isNotEmpty && parts.first is TextPart
                    ? (parts.first as TextPart).text
                    : "";

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    child: isUser
                        ? Text(text)
                        : MarkdownBody(data: text), // Dùng Markdown cho tin nhắn của AI
                  ),
                );
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "Hỏi gì đó về sách, quy định...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}