import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_expense_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // FIX: chỉ giữ selectedIndex ở đây vì nó ảnh hưởng đến layout ngoài
  int selectedIndex = 0;

  void _onBottomNavTap(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Lỗi xác thực: ${authSnapshot.error}'),
            ),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Vui lòng đăng nhập để xem dữ liệu')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),
          appBar: AppBar(
            title: const Text("Dashboard"),
            backgroundColor: Colors.green,
            elevation: 0,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("expenses")
                .where('userId', isEqualTo: user.uid)
                .orderBy("time", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // FIX: không truyền showBalance / showWeeklyTop xuống nữa
              // HomeScreenContent tự quản lý state của mình
              return HomeScreenContent(
                snapshot: snapshot,
                user: user,
                selectedIndex: selectedIndex,
                onBottomNavTap: _onBottomNavTap,
              );
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.green,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 6,
            child: SizedBox(
              height: 70,
              child: Row(
                children: [
                  _bottomBarItem(0, Icons.dashboard, "Tổng quan"),
                  _bottomBarItem(1, Icons.list_alt, "Sổ giao dịch"),
                  const SizedBox(width: 56),
                  _bottomBarItem(3, Icons.pie_chart, "Ngân sách"),
                  _bottomBarItem(4, Icons.account_circle, "Tài khoản"),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bottomBarItem(int index, IconData icon, String label) {
    final selected = selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onBottomNavTap(index),
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 22,
                  color: selected ? Colors.green : Colors.grey.shade600),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: selected ? Colors.green : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}

// FIX: Đổi từ StatelessWidget → StatefulWidget
// showBalance và showWeeklyTop giờ là state nội bộ của widget này
// Khi toggle, chỉ rebuild HomeScreenContent, KHÔNG động đến StreamBuilder bên ngoài
class HomeScreenContent extends StatefulWidget {
  final AsyncSnapshot<QuerySnapshot> snapshot;
  final User user;
  final int selectedIndex;
  final Function(int) onBottomNavTap;

  const HomeScreenContent({
    super.key,
    required this.snapshot,
    required this.user,
    required this.selectedIndex,
    required this.onBottomNavTap,
  });

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  // FIX: state được quản lý nội bộ, tách biệt với HomeScreen
  bool showBalance = true;
  bool showWeeklyTop = true;

  String formatMoney(num amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(amount)} ₫";
  }

  String formatDate(DateTime date) {
    return DateFormat("dd/MM/yyyy").format(date);
  }

  Widget summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: color.withOpacity(0.9))),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = widget.snapshot.data!.docs;
    double monthIncome = 0;
    double monthExpense = 0;
    double weekExpenseTotal = 0;
    final List<Map<String, dynamic>> weekExpenses = [];
    final List<Map<String, dynamic>> monthExpenses = [];
    final List<QueryDocumentSnapshot> recentDocs = [];

    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final currentMonthDays = List.generate(
      now.day,
      (index) => DateTime(now.year, now.month, index + 1),
    );

    final dailyIncome = {
      for (var date in currentMonthDays)
        DateFormat('yyyy-MM-dd').format(date): 0.0
    };
    final dailyExpense = {
      for (var date in currentMonthDays)
        DateFormat('yyyy-MM-dd').format(date): 0.0
    };

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final money = (data["money"] ?? 0).toDouble();
      final type = data["type"] ?? "expense";
      final time = (data["time"] as Timestamp?)?.toDate();
      if (time == null) continue;

      final monthKey = DateFormat('yyyy-MM').format(time);
      final dayKey = DateFormat('yyyy-MM-dd').format(time);

      if (monthKey == currentMonthKey) {
        if (type == "income") {
          monthIncome += money;
          if (dailyIncome.containsKey(dayKey)) {
            dailyIncome[dayKey] = dailyIncome[dayKey]! + money;
          }
        } else {
          monthExpense += money;
          if (dailyExpense.containsKey(dayKey)) {
            dailyExpense[dayKey] = dailyExpense[dayKey]! + money;
          }
        }

        if (type == "expense") {
          monthExpenses.add({
            "note": data["note"] ?? "",
            "amount": money,
            "date": time,
          });
        }
      }

      if (type == "expense" &&
          !time.isBefore(weekStart) &&
          !time.isAfter(weekEnd)) {
        weekExpenseTotal += money;
        weekExpenses.add({
          "note": data["note"] ?? "",
          "amount": money,
          "date": time,
        });
      }

      if (recentDocs.length < 3) {
        recentDocs.add(doc);
      }
    }

    weekExpenses.sort(
        (a, b) => (b["amount"] as double).compareTo(a["amount"] as double));
    monthExpenses.sort(
        (a, b) => (b["amount"] as double).compareTo(a["amount"] as double));

    final topWeek = weekExpenses.take(3).toList();
    final topMonth = monthExpenses.take(3).toList();
    final topData = showWeeklyTop ? topWeek : topMonth;
    final activeTotal = showWeeklyTop ? weekExpenseTotal : monthExpense;

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    for (int i = 0; i < currentMonthDays.length; i++) {
      final key = DateFormat('yyyy-MM-dd').format(currentMonthDays[i]);
      incomeSpots.add(FlSpot(i.toDouble() + 1, dailyIncome[key]!));
      expenseSpots.add(FlSpot(i.toDouble() + 1, dailyExpense[key]!));
    }

    final double maxY = [
      ...dailyIncome.values,
      ...dailyExpense.values,
    ].fold(0.0, (prev, value) => value > prev ? value : prev);
    final double chartMax = maxY > 0 ? maxY * 1.2 : 1000;
    final double yInterval = chartMax / 4;
    final double xInterval =
        currentMonthDays.length <= 8 ? 1 : currentMonthDays.length / 6;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0E9D58), Color(0xFF24B47E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Xin chào!",
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                widget.user.email ?? "Người dùng",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Số dư tài khoản",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          showBalance
                              ? formatMoney(monthIncome - monthExpense)
                              : "**********",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    // FIX: setState chỉ rebuild HomeScreenContent, không đụng StreamBuilder
                    onTap: () => setState(() => showBalance = !showBalance),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      child: Icon(
                        showBalance ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            summaryCard("Thu tháng", formatMoney(monthIncome),
                Icons.arrow_upward, Colors.green),
            const SizedBox(width: 12),
            summaryCard("Chi tháng", formatMoney(monthExpense),
                Icons.arrow_downward, Colors.red),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Biểu đồ thu chi",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: Colors.green, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text("Thu"),
                          const SizedBox(width: 12),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text("Chi"),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ReportScreen()),
                          );
                        },
                        child: const Text("Xem chi tiết"),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 260,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.black87,
                            getTooltipItems: (spots) {
                              return spots.map((spot) {
                                final label = spot.barIndex == 0 ? "Thu" : "Chi";
                                final index = spot.x.toInt() - 1;
                                final day = index >= 0 && index < currentMonthDays.length
                                    ? currentMonthDays[index]
                                    : null;
                                return LineTooltipItem(
                                  "$label\n${day != null ? DateFormat('dd/MM').format(day) : ''}\n${formatMoney(spot.y)}",
                                  const TextStyle(color: Colors.white, fontSize: 12),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: FlGridData(
                            show: true,
                            horizontalInterval: yInterval,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.withOpacity(0.2),
                                  strokeWidth: 1,
                                )),
                        borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.grey.shade300)),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              interval: yInterval,
                              getTitlesWidget: (value, meta) {
                                if (value < 0) return const SizedBox();
                                return Text(
                                  NumberFormat.compact(locale: 'vi_VN').format(value),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: xInterval,
                              reservedSize: 24,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt() - 1;
                                if (index < 0 || index >= currentMonthDays.length) {
                                  return const SizedBox();
                                }
                                if (currentMonthDays.length > 16 && index % 2 == 1) {
                                  return const SizedBox();
                                }
                                return Text(
                                  currentMonthDays[index].day.toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        minY: 0,
                        maxY: chartMax,
                        lineBarsData: [
                          LineChartBarData(
                            spots: incomeSpots,
                            color: Colors.green,
                            isCurved: true,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                                show: true,
                                color: Colors.green.withOpacity(0.15)),
                            barWidth: 3,
                          ),
                          LineChartBarData(
                            spots: expenseSpots,
                            color: Colors.red,
                            isCurved: true,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                                show: true,
                                color: Colors.red.withOpacity(0.15)),
                            barWidth: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Chi tiêu nhiều nhất",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ToggleButtons(
                    borderRadius: BorderRadius.circular(12),
                    selectedColor: Colors.white,
                    fillColor: Colors.green,
                    color: Colors.grey.shade700,
                    isSelected: [showWeeklyTop, !showWeeklyTop],
                    // FIX: setState chỉ rebuild HomeScreenContent, không đụng StreamBuilder
                    onPressed: (index) =>
                        setState(() => showWeeklyTop = !showWeeklyTop),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text("Tuần"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text("Tháng"),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (topData.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    showWeeklyTop
                        ? "Không có chi tiêu trong tuần."
                        : "Không có chi tiêu trong tháng.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              else
                Column(
                  children: topData.map((item) {
                    final amount = item["amount"] as double;
                    final percent =
                        activeTotal > 0 ? amount / activeTotal * 100 : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["note"].toString().isEmpty
                                      ? "Không có ghi chú"
                                      : item["note"].toString(),
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatDate(item["date"] as DateTime),
                                  style: TextStyle(
                                      color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${percent.toStringAsFixed(0)}%",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Giao dịch gần đây",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ReportScreen()),
                );
              },
              child: const Text("Xem tất cả"),
            )
          ],
        ),
        const SizedBox(height: 8),
        ...recentDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final money = (data["money"] ?? 0).toDouble();
          final type = data["type"] ?? "expense";
          final note = data["note"] ?? "";
          final time = (data["time"] as Timestamp?)?.toDate();
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: type == "income"
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                child: Icon(
                  type == "income" ? Icons.arrow_downward : Icons.arrow_upward,
                  color: type == "income" ? Colors.green : Colors.red,
                ),
              ),
              title: Text(note.isEmpty
                  ? (type == "income" ? "Thu nhập" : "Chi tiêu")
                  : note),
              subtitle: Text(
                time != null ? formatDate(time) : "",
                style: const TextStyle(fontSize: 12),
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
        }),
        const SizedBox(height: 90),
      ],
    );
  }
}