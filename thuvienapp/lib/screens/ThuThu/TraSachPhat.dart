import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../providers/api_service.dart';
import '../../models/user.dart';

class ReturnAndFineScreen extends StatefulWidget {
  final User user;
  const ReturnAndFineScreen({required this.user});

  @override
  _ReturnAndFineScreenState createState() => _ReturnAndFineScreenState();
}

class _ReturnAndFineScreenState extends State<ReturnAndFineScreen> {
  final _maPhieuController = TextEditingController();
  final _maSachController = TextEditingController();
  final ApiService _api = ApiService();
  String _resultMessage = "";
  Color _msgColor = Colors.black;

  void _processReturn() async {
    if(_maPhieuController.text.isEmpty || _maSachController.text.isEmpty) return;

    int mp = int.tryParse(_maPhieuController.text) ?? 0;
    int ms = int.tryParse(_maSachController.text) ?? 0;

    var res = await _api.traSach(mp, ms);

    setState(() {
      if(res['success']) {
        double phat = (res['data']['tienPhat'] ?? 0).toDouble();
        if(phat > 0) {
          String money = NumberFormat("#,##0").format(phat);
          _resultMessage = "Trả thành công. QUÁ HẠN! Phạt: $money đ";
          _msgColor = Colors.red;
        } else {
          _resultMessage = "Trả sách thành công. Không phạt.";
          _msgColor = Colors.green;
        }
      } else {
        _resultMessage = res['message'];
        _msgColor = Colors.red;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kiểm Tra & Trả Sách")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _maPhieuController,
              decoration: InputDecoration(labelText: "Nhập Mã Phiếu Mượn", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 15),
            TextField(
              controller: _maSachController,
              decoration: InputDecoration(labelText: "Nhập Mã Sách (ID)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: Icon(Icons.assignment_return),
                label: Text("XÁC NHẬN TRẢ SÁCH"),
                onPressed: _processReturn,
              ),
            ),
            SizedBox(height: 30),
            if(_resultMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(15),
                width: double.infinity,
                color: _msgColor.withOpacity(0.1),
                child: Text(_resultMessage, style: TextStyle(color: _msgColor, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              )
          ],
        ),
      ),
    );
  }
}