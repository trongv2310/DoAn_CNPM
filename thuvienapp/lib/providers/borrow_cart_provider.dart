import 'package:flutter/material.dart';
import '../models/sach.dart';

// 1. Class CartItem (Dùng để lưu thông tin chi tiết trong giỏ)
class CartItem {
  final String id;
  final Sach sach;
  final int quantity;

  CartItem({
    required this.id,
    required this.sach,
    required this.quantity,
  });
}

class BorrowCartProvider with ChangeNotifier {
  // 2. Lưu trữ: Key là Mã Sách (int), Value là CartItem
  Map<int, CartItem> _items = {};

  // Getter lấy danh sách items
  Map<int, CartItem> get items {
    return {..._items};
  }

  // Đếm số lượng loại sách trong giỏ
  int get itemCount {
    return _items.length;
  }

  // 3. Tính tổng tiền (Quan trọng cho hóa đơn)
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.sach.giamuon * cartItem.quantity;
    });
    return total;
  }

  // Hàm lấy số lượng của một cuốn sách cụ thể (để hiện trong trang chi tiết)
  int getQuantity(Sach sach) {
    if (_items.containsKey(sach.masach)) {
      return _items[sach.masach]!.quantity;
    }
    return 0;
  }

  // Thêm hoặc cập nhật sách vào giỏ
  void add(Sach sach, int quantity) {
    if (_items.containsKey(sach.masach)) {
      // Nếu sách đã có -> Cập nhật số lượng mới
      _items.update(
        sach.masach,
            (existingItem) => CartItem(
          id: existingItem.id,
          sach: existingItem.sach,
          quantity: quantity,
        ),
      );
    } else {
      // Nếu chưa có -> Thêm mới
      _items.putIfAbsent(
        sach.masach,
            () => CartItem(
          id: DateTime.now().toString(),
          sach: sach,
          quantity: quantity,
        ),
      );
    }
    notifyListeners();
  }

  // Xóa 1 sách khỏi giỏ dựa trên mã sách
  void remove(int maSach) {
    _items.remove(maSach);
    notifyListeners();
  }

  // Xóa sạch giỏ (Sau khi mượn thành công)
  void clear() {
    _items = {};
    notifyListeners();
  }
}