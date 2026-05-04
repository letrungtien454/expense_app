import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetScreen extends StatelessWidget {
  final User user;
  const BudgetScreen({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Ngân sách tháng",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: const [
              Text(
                "Mục tiêu tiết kiệm",
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                "5,000,000 ₫",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: 0.6,
          minHeight: 12,
          borderRadius: BorderRadius.circular(20),
          backgroundColor: Colors.grey.shade300,
          color: Colors.green,
        ),
        const SizedBox(height: 10),
        const Text(
          "Đã sử dụng 60% ngân sách",
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}