import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool obscure = true;

  void submit() async {
    String email = emailController.text.trim();
    String pass = passController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      showMsg("Nhập đầy đủ thông tin");
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email, password: pass);
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email, password: pass);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } catch (e) {
      showMsg("Sai tài khoản hoặc mật khẩu");
    }

    setState(() => isLoading = false);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              margin: EdgeInsets.all(20),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet,
                        size: 60, color: Colors.green),

                    SizedBox(height: 10),
                    Text(
                      isLogin ? "Đăng nhập" : "Đăng ký",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),

                    SizedBox(height: 20),

                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    SizedBox(height: 10),

                    TextField(
                      controller: passController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: "Mật khẩu",
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscure
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              obscure = !obscure;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    SizedBox(height: 20),

                    isLoading
                        ? CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: submit,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                isLogin ? "Đăng nhập" : "Đăng ký",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),

                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLogin = !isLogin;
                        });
                      },
                      child: Text(isLogin
                          ? "Chưa có tài khoản? Đăng ký"
                          : "Đã có tài khoản? Đăng nhập"),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}