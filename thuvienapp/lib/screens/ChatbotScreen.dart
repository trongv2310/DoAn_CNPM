import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// Đảm bảo import đúng đường dẫn tới model và api service của bạn
import '../models/sach.dart';
import '../providers/api_service.dart';

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
  bool _isInitializing = true; // Thêm biến loading khi đang khởi tạo

  @override
  void initState() {
    super.initState();
    _initializeGemini();
  }

  // Chuyển thành Future<void> và async để chờ lấy dữ liệu
  Future<void> _initializeGemini() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint("LỖI: Chưa cấu hình GEMINI_API_KEY trong file .env");
      setState(() {
        _isInitSuccess = false;
        _isInitializing = false;
      });
      return;
    }

    try {
      // BƯỚC 1: LẤY DỮ LIỆU TỪ DB THÔNG QUA API
      // (Giả sử ApiService có hàm getAllSach hoặc getBooks trả về List<Sach>)
      // Bạn cần kiểm tra lại tên hàm trong ApiService của bạn
      List<Sach> danhSachSach = [];
      try {
        danhSachSach = await ApiService().fetchSaches();
      } catch (e) {
        debugPrint("Lỗi lấy dữ liệu sách cho AI: $e");
        // Nếu lỗi API, AI vẫn hoạt động nhưng không có data sách mới nhất
      }

      // BƯỚC 2: CHUYỂN DỮ LIỆU THÀNH CHUỖI VĂN BẢN ĐỂ AI HIỂU
      String databaseContext = "";
      if (danhSachSach.isNotEmpty) {
        databaseContext = danhSachSach.map((s) {
          // Chỉ lấy những trường cần thiết để tiết kiệm token
          return "- Tên: ${s.tensach} | Tác giả: ${s.tenTacGia} | Thể loại: ${s.theLoai} | Tồn kho: ${s.soluongton}";
        }).join("\n");
      } else {
        databaseContext = "Hiện chưa cập nhật được danh sách sách từ hệ thống.";
      }

      // BƯỚC 3: CẬP NHẬT SYSTEM INSTRUCTION
      final systemInstruction = """
Bạn là "Trợ lý tư vấn AI" của hệ thống quản lý thư viện.
Nhiệm vụ: Hỗ trợ tìm sách, báo giá và giải đáp thắc mắc dựa trên dữ liệu thực tế bên dưới.

--- DỮ LIỆU KHO SÁCH THỰC TẾ (DB) ---
Dưới đây là danh sách các sách hiện có trong thư viện. Bạn CHỈ ĐƯỢC tư vấn các sách có trong danh sách này. Nếu sách có tồn kho = 0, hãy báo là tạm hết hàng.
$databaseContext
-------------------------------------

CHÍNH SÁCH & GIÁ (Cố định):
- Giá thuê: 5.000 VNĐ/7 ngày (Sách thường), 10.000 VNĐ/7 ngày (Sách hiếm/mới).
- Cọc: 50.000 VNĐ/quyển (Hoàn lại khi trả).
- Phí trễ: 2.000 VNĐ/ngày.

QUY TẮC TRẢ LỜI:
1. Khi khách hỏi sách, hãy tra cứu trong [DỮ LIỆU KHO SÁCH THỰC TẾ] ở trên.
2. Nếu sách không có trong danh sách, hãy xin lỗi và bảo thư viện chưa nhập sách này.
3. Luôn báo giá thuê và tiền cọc rõ ràng bằng đơn vị VNĐ.
4. Trả lời ngắn gọn, thân thiện.
""";

      _model = GenerativeModel(
        model: 'gemini-2.5-flash', // Khuyên dùng 1.5-flash vì context window lớn hơn, chứa được nhiều sách hơn
        apiKey: apiKey,
        systemInstruction: Content.system(systemInstruction),
      );

      _chatSession = _model.startChat(history: _history);
      setState(() {
        _isInitSuccess = true;
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint("Lỗi khởi tạo Gemini: $e");
      setState(() {
        _isInitSuccess = false;
        _isInitializing = false;
      });
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
      final response = await _chatSession.sendMessage(Content.text(message));

      setState(() {
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _loading = false;
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
    // Hiển thị màn hình chờ khi đang tải dữ liệu sách và khởi tạo AI
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text("Trợ lý Thư Viện AI")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Đang tải dữ liệu sách...")
            ],
          ),
        ),
      );
    }

    if (!_isInitSuccess) {
      return Scaffold(
        appBar: AppBar(title: const Text("Lỗi Cấu Hình")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "Không thể khởi tạo AI. Vui lòng kiểm tra kết nối mạng hoặc API Key.",
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
                // Gọi lại initialize để cập nhật dữ liệu sách mới nhất nếu có
                _isInitializing = true;
              });
              _initializeGemini();
            },
            tooltip: "Làm mới cuộc trò chuyện",
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: history.isEmpty
                ? const Center(child: Text("Hỏi tôi về các sách đang có trong thư viện!"))
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
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
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