import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionScreen extends StatelessWidget {
  final User user;
  const TransactionScreen({required this.user, super.key});

  String formatMoney(num amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(amount)} ₫";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("expenses")
          .where('userId', isEqualTo: user.uid)
          .orderBy("time", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("Chưa có giao dịch"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final money = (data["money"] ?? 0).toDouble();
            final note = data["note"] ?? "";
            final type = data["type"] ?? "expense";
            final category = data["category"] ?? "";
            final time = (data["time"] as Timestamp?)?.toDate();

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: type == "income"
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Icon(
                    type == "income"
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: type == "income" ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(note.isEmpty ? "Không có ghi chú" : note),
                subtitle: Text(
                  "$category\n${time != null ? DateFormat("dd/MM/yyyy").format(time) : ""}",
                ),
                trailing: Text(
                  (type == "income" ? "+" : "-") + formatMoney(money),
                  style: TextStyle(
                    color: type == "income" ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}