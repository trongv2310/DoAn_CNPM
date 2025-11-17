import 'package:flutter/material.dart';

class BorrowedBook {
  final String title;
  final String author;
  final String initialLetters;
  final Color backgroundColor;
  final String borrowDate;
  final String returnDate;
  final String timeLeft;
  final bool isNearDue;

  const BorrowedBook({
    required this.title,
    required this.author,
    required this.initialLetters,
    required this.backgroundColor,
    required this.borrowDate,
    required this.returnDate,
    required this.timeLeft,
    this.isNearDue = false,
  });
}
