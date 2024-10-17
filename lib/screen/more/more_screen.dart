import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:handong_eats/screen/login/login_screen.dart';
import 'package:handong_eats/screen/main_screen.dart';
import 'package:handong_eats/screen/order/widget/order_list_widget.dart';
import 'package:handong_eats/util/util.dart' as util;
import 'package:http/http.dart' as http;

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final storage = const FlutterSecureStorage(); // SecureStorage 인스턴스
  bool isLoggedIn = false; // 로그인 상태
  bool isLoading = true; // 로딩 상태 확인
  dynamic userInfo; // 주문 내역 리스트

  @override
  void initState() {
    super.initState();
    checkLoginStatus(); // 로그인 상태 확인
    fetchUserInfo();
  }

  // 로그인 상태 확인
  Future<void> checkLoginStatus() async {
    isLoggedIn = await util.isLoggedIn(); // 토큰이 있으면 로그인 상태로 간주
    setState(() {});
  }

  // 로그아웃 (토큰 제거)
  Future<void> logout() async {
    await storage.deleteAll(); // 저장된 모든 토큰 제거
    setState(() {
      isLoggedIn = false; // 로그아웃 상태로 변경
    });
    // 로그인 화면으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  // 서버에서 주문 내역을 가져오는 함수
  Future<void> fetchUserInfo() async {
    const String apiUrl = 'http://127.0.0.1:3000/users';

    try {
      final String? accessToken = await util.getAccessToken();

      if (accessToken == null) {
        print('AccessToken이 없습니다.');
        return;
      }

      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      });

      if (response.statusCode == 200) {
        final dynamic user = jsonDecode(response.body);
        setState(() {
          userInfo = user; // 주문 내역 저장
          isLoading = false; // 로딩 완료
        });
      } else {
        print('Failed to load user: ${response.statusCode}');
        setState(() {
          isLoading = false; // 로딩 실패 시에도 상태 갱신
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false; // 에러 발생 시 로딩 상태 갱신
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20.0, vertical: 30.0), // 화면 가장자리 패딩 조정
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 한동 Pay 잔액 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '한동 Pay',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  userInfo != null && userInfo['point'] != null
                      ? '${userInfo['point']} 포인트'
                      : '0 포인트', // userInfo 또는 point 값이 없을 경우 기본값으로 '0'을 출력
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40), // 상단과 첫 버튼 사이 간격
            // 한동 Pay 충전 버튼
            ElevatedButton(
              onPressed: () {
                // 충전 페이지로 이동
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 15), // 버튼 높이 조정
              ),
              child: const Text(
                '한동 Pay 충전',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 30), // 버튼 간 간격
            // 주문 내역 버튼
            ElevatedButton(
              onPressed: () {
                util.checkLoginAndExecute(context, () async {
                  // 주문 내역 페이지로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderHistoryScreen(),
                    ),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 15), // 버튼 높이 조정
              ),
              child: const Text(
                '주문 내역',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 30), // 버튼 간 간격
            // 문의하기 버튼
            ElevatedButton(
              onPressed: () {
                // 문의하기 페이지로 이동
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 15), // 버튼 높이 조정
              ),
              child: const Text(
                '문의하기',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 30), // 버튼 간 간격
            // 회원정보 수정 버튼
            ElevatedButton(
              onPressed: () {
                // 회원정보 수정 페이지로 이동
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 15), // 버튼 높이 조정
              ),
              child: const Text(
                '회원정보 수정',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 30), // 버튼 간 간격
            // 로그인/로그아웃 버튼
            ElevatedButton(
              onPressed: isLoggedIn
                  ? logout
                  : () {
                      // 로그인 페이지로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 15), // 버튼 높이 조정
              ),
              child: Text(
                isLoggedIn ? '로그아웃' : '로그인',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
            const Spacer(),
            // 앱 버전 정보
            const Center(
              child: Text(
                'Version: 1.0.2',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
