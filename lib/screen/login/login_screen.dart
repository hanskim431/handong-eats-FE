import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:handong_eats/screen/main_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

// 상수 및 스타일 정의
const kPrimaryColor = Color(0xFF005C99);
const kButtonPadding = EdgeInsets.symmetric(vertical: 15);
const kButtonTextStyle = TextStyle(fontSize: 20, color: Colors.white);
const kOutlinedButtonTextStyle = TextStyle(fontSize: 20, color: kPrimaryColor);
const kLoginInfoTextStyle = TextStyle(fontSize: 16, color: Colors.black54);

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess; // 로그인 성공 후 호출될 콜백
  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  bool obscureText = true; // 비밀번호 표시 여부
  bool isLoading = false; // 로딩 상태 표시를 위한 변수
  final storage = const FlutterSecureStorage();
  final logger = Logger(); // Logger 인스턴스 생성

  Future<void> login() async {
    setState(() {
      isLoading = true; // 로그인 요청 중 로딩 표시
    });

    final url = Uri.parse('http://127.0.0.1:3000/users/login'); // 로그인 API URL
    final body = jsonEncode({
      'userId': idController.text,
      'password': pwController.text,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        await storage.write(key: 'accessToken', value: accessToken);
        await storage.write(key: 'refreshToken', value: refreshToken);

        // 로그인 성공 시 콜백 호출
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }

        // 성공 시 메인 페이지로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        final errorData = jsonDecode(response.body);
        logger.e('Login Failed: ${errorData['message']}');
        showErrorSnackBar(context, 'Login Failed: ${errorData['message']}');
      }
    } catch (e) {
      logger.e('An error occurred: $e');
      showErrorSnackBar(context, 'An error occurred during login.');
    } finally {
      setState(() {
        isLoading = false; // 로그인 완료 후 로딩 상태 해제
      });
    }
  }

  // 에러 메시지를 스낵바로 보여주는 함수
  void showErrorSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LOGIN"),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Image(
                image: AssetImage('assets/images/handong-logo.jpg'), // 로고 경로 설정
                height: 100, // 로고 크기
              ),
            ),
            const SizedBox(height: 30),
            buildTextField(
              controller: idController,
              labelText: 'ID',
              obscureText: false,
            ),
            const SizedBox(height: 15),
            buildTextField(
              controller: pwController,
              labelText: 'PW',
              obscureText: obscureText,
              togglePasswordVisibility: () {
                setState(() {
                  obscureText = !obscureText; // 비밀번호 가리기 토글
                });
              },
            ),
            const SizedBox(height: 30),
            buildLoginButton(),
            const SizedBox(height: 20),
            buildSignUpButton(),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                '한동딜리버리 회원이 되시면 할인과\n다양한 프로모션 혜택이 제공됩니다.',
                textAlign: TextAlign.center,
                style: kLoginInfoTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 로그인 버튼
  ElevatedButton buildLoginButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : login,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        padding: kButtonPadding,
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('로그인', style: kButtonTextStyle),
    );
  }

  // 회원가입 버튼
  OutlinedButton buildSignUpButton() {
    return OutlinedButton(
      onPressed: () {
        // 회원가입 페이지 이동 로직
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kPrimaryColor, width: 2),
        padding: kButtonPadding,
      ),
      child: const Text('회원가입', style: kOutlinedButtonTextStyle),
    );
  }

  // 텍스트 입력 필드
  Widget buildTextField({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
    VoidCallback? togglePasswordVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        suffixIcon: togglePasswordVisibility != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: togglePasswordVisibility,
              )
            : null,
      ),
    );
  }
}
