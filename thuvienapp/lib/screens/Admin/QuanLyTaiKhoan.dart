import 'package:flutter/material.dart';
import '../../providers/api_service.dart';
import 'AddUser.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    var list = await _apiService.getAllUsers();
    setState(() {
      _users = list;
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) => status == "Hoạt động" ? Colors.green : Colors.red;

  void _toggleStatus(int id, String currentStatus) async {
    String newStatus = currentStatus == "Hoạt động" ? "Ngừng hoạt động" : "Hoạt động";
    bool success = await _apiService.updateUserStatus(id, newStatus);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã cập nhật: $newStatus")));
      _loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi cập nhật trạng thái")));
    }
  }

  void _deleteUser(int id, String username) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa tài khoản '$username'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await _apiService.deleteUser(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Xóa thành công!")));
        _loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Không thể xóa (Có ràng buộc dữ liệu)")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quản Lý Tài Khoản")),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.person_add),
        backgroundColor: Colors.blue,
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => AddUserScreen()));
          _loadUsers();
        },
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text(user['tendangnhap'], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Quyền: ${user['tenQuyen']} - ${user['trangthai']}",
                  style: TextStyle(color: _getStatusColor(user['trangthai'] ?? ""))),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(user['trangthai'] == "Hoạt động" ? Icons.lock_open : Icons.lock),
                    onPressed: () => _toggleStatus(user['mataikhoan'], user['trangthai']),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteUser(user['mataikhoan'], user['tendangnhap']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}