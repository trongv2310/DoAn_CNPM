import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
  bool _isInitSuccess = false;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
  }

  void _initializeGemini() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint("LỖI: Chưa cấu hình GEMINI_API_KEY trong file .env");
      setState(() => _isInitSuccess = false);
      return;
    }

    try {
      // Nội dung chỉ dẫn cho AI (Giữ nguyên nội dung của bạn)
      final systemInstruction = """
Bạn là "Thủ thư tư vấn AI" chuyên nghiệp của Hệ thống Thư viện. Nhiệm vụ của bạn là khơi gợi niềm đam mê đọc sách và hỗ trợ độc giả mượn sách.

KIẾN THỨC VỀ KHO SÁCH:
- Bạn biết thông tin: Tên sách, Tác giả, Thể loại, NXB, và số lượng tồn kho.
- Bạn hiểu rõ nội dung các thể loại sách để đưa ra lời khuyên phù hợp.

CHÍNH SÁCH GIÁ THUÊ & QUY ĐỊNH (Quan trọng):
- Giá thuê cơ bản: Đồng giá 5.000 VNĐ / 7 ngày cho các loại sách thông thường.
- Sách mới/Sách hiếm: 10.000 VNĐ / 7 ngày.
- Tiền đặt cọc: Độc giả cần đặt cọc 50.000 VNĐ cho mỗi lần mượn (số tiền này sẽ được hoàn lại khi trả sách).
- Phí quá hạn: 2.000 VNĐ / mỗi ngày trả muộn.
- Miễn phí: Đối với các loại sách giáo khoa hoặc tài liệu nghiên cứu nội bộ.

NHIỆM VỤ CỦA BẠN:
1. Gợi ý sách dựa trên sở thích và **luôn chủ động báo giá thuê** cho độc giả khi giới thiệu.
2. Giải thích rõ về số tiền đặt cọc để độc giả chuẩn bị trước khi đến thư viện.
3. Hướng dẫn quy trình: Chọn sách -> Xem giá & cọc -> Thêm vào giỏ hàng -> Chờ duyệt.

PHONG CÁCH TRẢ LỜI:
- Thân thiện, tận tâm, xưng "Trợ lý Thủ thư".
- Khi báo giá, hãy dùng đơn vị "VNĐ" rõ ràng.
- Ví dụ: "Cuốn sách 'Đắc Nhân Tâm' thuộc thể loại Kỹ năng sống hiện đang có sẵn. Giá thuê chỉ 5.000 VNĐ cho 1 tuần, bạn chỉ cần cọc thêm một chút phí nhỏ thôi nhé!"
""";

      // Truyền systemInstruction vào và sửa tên model
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(systemInstruction), //Dòng này giúp AI nhận việc
      );

      _chatSession = _model.startChat(history: _history);
      setState(() => _isInitSuccess = true);
    } catch (e) {
      debugPrint("Lỗi khởi tạo Gemini: $e");
      setState(() => _isInitSuccess = false);
    }
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty || _loading) return;

    setState(() {
      _loading = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      // Gửi tin nhắn đến Gemini
      final response = await _chatSession.sendMessage(Content.text(message));

      setState(() {
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _loading = false;
        // Báo lỗi chi tiết nếu có sự cố
        debugPrint("Chatbot Error: $e");
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${e.toString()}")),
        );
      }
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
    if (!_isInitSuccess) {
      return Scaffold(
        appBar: AppBar(title: const Text("Lỗi Cấu Hình")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "Không thể khởi tạo AI. Vui lòng kiểm tra lại GEMINI_API_KEY trong file .env và đảm bảo model 'gemini-1.5-flash' được hỗ trợ.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ),
      );
    }

    final history = _chatSession.history.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trợ lý Thư Viện AI"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _history.clear();
                _chatSession = _model.startChat(history: _history);
              });
            },
            tooltip: "Làm mới cuộc trò chuyện",
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: history.isEmpty
                ? const Center(child: Text("Hỏi tôi bất cứ điều gì về thư viện!"))
                : ListView.builder(
              controller: _scrollController,
              itemCount: history.length,
              itemBuilder: (context, index) {
                final content = history[index];
                final isUser = content.role == 'user';
                final text = content.parts
                    .whereType<TextPart>()
                    .map((e) => e.text)
                    .join('');

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: Radius.circular(isUser ? 15 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 15),
                      ),
                    ),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8
                    ),
                    child: isUser
                        ? Text(text, style: const TextStyle(fontSize: 16))
                        : MarkdownBody(
                      data: text,
                      selectable: true,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: "Nhập câu hỏi...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}