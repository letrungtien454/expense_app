import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatelessWidget {

  String formatMoney(num amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(amount)} ₫";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Báo cáo")),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("expenses").snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          Map<String, double> monthlyIncome = {};
          Map<String, double> monthlyExpense = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            final money = (data["money"] ?? 0).toDouble();
            final type = data["type"] ?? "expense";
            final time = (data["time"] as Timestamp?)?.toDate();

            if (time == null) continue;

            String month = DateFormat("MM/yyyy").format(time);

            if (type == "income") {
              monthlyIncome[month] = (monthlyIncome[month] ?? 0) + money;
            } else {
              monthlyExpense[month] = (monthlyExpense[month] ?? 0) + money;
            }
          }

          final months = {...monthlyIncome.keys, ...monthlyExpense.keys}.toList();

          return ListView.builder(
            itemCount: months.length,
            itemBuilder: (context, index) {

              String m = months[index];

              return ListTile(
                title: Text("Tháng $m"),
                subtitle: Text(
                    "Thu: ${formatMoney(monthlyIncome[m] ?? 0)} | Chi: ${formatMoney(monthlyExpense[m] ?? 0)}"),
              );
            },
          );
        },
      ),
    );
  }
}