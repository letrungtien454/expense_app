import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // bắt buộc
  await Firebase.initializeApp(); // khởi tạo Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen());
  }
}

class Expense {
  String amount;
  String note;
  String type; // income or expense

  Expense({required this.amount, required this.note, required this.type});
}

class ExpenseScreen extends StatefulWidget {
  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String selectedType = "expense"; // mặc định là chi

  List<Expense> expenses = [];

  void addExpense() {
    String amount = amountController.text;
    String note = noteController.text;

    if (amount.isEmpty) return;

    setState(() {
      expenses.add(Expense(amount: amount, note: note, type: selectedType));
    });

    amountController.clear();
    noteController.clear();
  }

  int getIncome() {
    int total = 0;
    for (var e in expenses) {
      if (e.type == "income") {
        total += int.tryParse(e.amount) ?? 0;
      }
    }
    return total;
  }

  int getExpense() {
    int total = 0;
    for (var e in expenses) {
      if (e.type == "expense") {
        total += int.tryParse(e.amount) ?? 0;
      }
    }
    return total;
  }

  int getBalance() {
    return getIncome() - getExpense();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quản lý chi tiêu")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔥 TỔNG
            Text(
              "Số dư: ${getBalance()} VND",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "Thu: ${getIncome()} VND",
              style: TextStyle(color: Colors.green),
            ),
            Text(
              "Chi: ${getExpense()} VND",
              style: TextStyle(color: Colors.red),
            ),

            SizedBox(height: 20),

            // 🔥 INPUT
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Số tiền",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: "Ghi chú",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 10),

            // 🔥 CHỌN THU / CHI
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: Text("Chi"),
                    value: "expense",
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value.toString();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: Text("Thu"),
                    value: "income",
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value.toString();
                      });
                    },
                  ),
                ),
              ],
            ),

            ElevatedButton(onPressed: addExpense, child: Text("Thêm")),

            SizedBox(height: 20),

            // 🔥 DANH SÁCH
            Expanded(
              child: ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  var e = expenses[index];
                  return Card(
                    child: ListTile(
                      title: Text("${e.amount} VND"),
                      subtitle: Text(e.note),
                      trailing: Text(
                        e.type == "income" ? "Thu" : "Chi",
                        style: TextStyle(
                          color: e.type == "income" ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
