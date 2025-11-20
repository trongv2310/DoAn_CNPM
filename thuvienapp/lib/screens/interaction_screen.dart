import 'package:flutter/material.dart';

class InteractionScreen extends StatelessWidget {
  const InteractionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tương Tác'),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                icon: Icon(Icons.question_answer),
                text: 'Hỏi đáp',
              ),
              Tab(
                icon: Icon(Icons.feedback),
                text: 'Góp ý',
              ),
              Tab(
                icon: Icon(Icons.star_rate),
                text: 'Đánh giá sách',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            QATab(),
            FeedbackTab(),
            BookReviewTab(),
          ],
        ),
      ),
    );
  }
}

// Tab Hỏi đáp
class QATab extends StatelessWidget {
  const QATab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Hỏi đáp',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Đặt câu hỏi của bạn về sách, thủ tục mượn/trả, hoặc bất kỳ thắc mắc nào về thư viện.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildQACard(
          'Làm thế nào để mượn sách?',
          'Bạn có thể mượn sách bằng cách chọn sách từ danh sách và nhấn nút "Mượn sách". Thời gian mượn tối đa là 30 ngày.',
        ),
        const SizedBox(height: 12),
        _buildQACard(
          'Có thể gia hạn sách không?',
          'Có, bạn có thể gia hạn sách 1 lần duy nhất nếu không có người khác đặt trước sách đó.',
        ),
        const SizedBox(height: 12),
        _buildQACard(
          'Phí phạt trả trễ là bao nhiêu?',
          'Phí phạt trả trễ là 5.000đ/ngày. Vui lòng trả sách đúng hạn để tránh phí phạt.',
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng đặt câu hỏi mới sẽ được cập nhật sớm')),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Đặt câu hỏi mới'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildQACard(String question, String answer) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// Tab Góp ý
class FeedbackTab extends StatelessWidget {
  const FeedbackTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Góp ý',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Chúng tôi luôn lắng nghe ý kiến đóng góp từ bạn để cải thiện dịch vụ thư viện.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gửi góp ý của bạn',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Nội dung góp ý',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.message),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cảm ơn bạn đã gửi góp ý!')),
                      );
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Gửi góp ý'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Góp ý gần đây',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildFeedbackCard(
          'Nguyễn Văn A',
          'Nên thêm nhiều sách về lập trình',
          '2 ngày trước',
          Icons.computer,
        ),
        const SizedBox(height: 8),
        _buildFeedbackCard(
          'Trần Thị B',
          'Thời gian mở cửa thư viện nên kéo dài hơn',
          '5 ngày trước',
          Icons.access_time,
        ),
      ],
    );
  }

  Widget _buildFeedbackCard(String name, String feedback, String time, IconData icon) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent.withOpacity(0.1),
          child: Icon(icon, color: Colors.blueAccent),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(feedback),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

// Tab Đánh giá sách
class BookReviewTab extends StatelessWidget {
  const BookReviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Đánh giá sách',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Chia sẻ cảm nhận của bạn về những cuốn sách đã đọc.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildReviewCard(
          'Nhà Giả Kim',
          'Paulo Coelho',
          5,
          'Một cuốn sách tuyệt vời về hành trình tìm kiếm ước mơ. Rất đáng đọc!',
          'Lê Văn C',
          '1 tuần trước',
        ),
        const SizedBox(height: 12),
        _buildReviewCard(
          'Đắc Nhân Tâm',
          'Dale Carnegie',
          4,
          'Cuốn sách giúp cải thiện kỹ năng giao tiếp và quan hệ xã hội.',
          'Phạm Thị D',
          '2 tuần trước',
        ),
        const SizedBox(height: 12),
        _buildReviewCard(
          'Sapiens: Lược Sử Loài Người',
          'Yuval Noah Harari',
          5,
          'Góc nhìn mới mẻ về lịch sử nhân loại. Rất nhiều thông tin thú vị!',
          'Hoàng Văn E',
          '3 tuần trước',
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng viết đánh giá sẽ được cập nhật sớm')),
            );
          },
          icon: const Icon(Icons.edit),
          label: const Text('Viết đánh giá'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(
    String bookTitle,
    String author,
    int rating,
    String review,
    String reviewer,
    String time,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        author,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(review, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  reviewer,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
