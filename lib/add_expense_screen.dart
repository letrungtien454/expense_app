import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddExpenseScreen extends StatefulWidget {
  @override
  _AddExpenseScreenState createState() =>
      _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {

  final moneyController = TextEditingController();
  final noteController = TextEditingController();

  String type = "expense";

  // 🔥 DANH MỤC
  List<String> expenseCategories = [
    "Ăn uống",
    "Mua sắm",
    "Đi lại",
    "Giải trí",
  ];

  List<String> incomeCategories = [
    "Lương",
    "Thưởng",
    "Đầu tư",
  ];

  String? selectedCategory;

  void save() async {
    final user = FirebaseAuth.instance.currentUser;

    if (moneyController.text.isEmpty || selectedCategory == null) return;

    await FirebaseFirestore.instance.collection("expenses").add({
      "userId": user?.uid,
      "money": double.parse(moneyController.text),
      "note": noteController.text,
      "type": type,
      "category": selectedCategory, // 🔥 thêm category
      "time": Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    // 🔥 chọn list theo type
    List<String> categories =
        type == "expense" ? expenseCategories : incomeCategories;

    return Scaffold(
      appBar: AppBar(title: Text("Thêm giao dịch")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            // 🔥 chọn thu / chi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ChoiceChip(
                  label: Text("Chi"),
                  selected: type == "expense",
                  onSelected: (_) {
                    setState(() {
                      type = "expense";
                      selectedCategory = null;
                    });
                  },
                ),
                ChoiceChip(
                  label: Text("Thu"),
                  selected: type == "income",
                  onSelected: (_) {
                    setState(() {
                      type = "income";
                      selectedCategory = null;
                    });
                  },
                ),
              ],
            ),

            SizedBox(height: 20),

            // 🔥 DROPDOWN DANH MỤC
            DropdownButtonFormField<String>(
              hint: Text("Chọn danh mục"),
              value: selectedCategory,
              items: categories.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            SizedBox(height: 20),

            TextField(
              controller: moneyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Số tiền"),
            ),

            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: "Ghi chú"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: save,
              child: Text("Lưu"),
            )
          ],
        ),
      ),
    );
  }
}