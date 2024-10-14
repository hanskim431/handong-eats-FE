// MongoDB의 $date 필드를 DateTime으로 변환
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:handong_eats/screen/login/login_screen.dart';

DateTime convertDate(dynamic dateField) {
  if (dateField is Map && dateField.containsKey('\$date')) {
    final dateValue = dateField['\$date'];
    if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    }
  }
  return DateTime.now(); // 기본적으로 현재 시간을 반환하도록 함
}

// FlutterSecureStorage에서 accessToken을 가져오는 함수
Future<String?> getAccessToken() async {
  const FlutterSecureStorage secureStorage =
      FlutterSecureStorage(); // SecureStorage 인스턴스 생성

  return await secureStorage.read(key: 'accessToken'); // accessToken을 가져옴
}

// 로그인 상태 검사하는 함수
Future<bool> isLoggedIn() async {
  const storage = FlutterSecureStorage();
  String? accessToken = await storage.read(key: 'accessToken');
  return accessToken != null;
}

// 로그 아웃이면 로그인 페이지로 이동하는 함수
void checkLoginAndExecute(
    BuildContext context, Future<void> Function() action) async {
  bool loggedIn = await isLoggedIn();
  if (loggedIn) {
    await action(); // 로그인 상태일 경우 동작 실행
  } else {
    // 로그인 상태가 아닐 경우 로그인 화면으로 이동 후 성공 시 동작 실행
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          onLoginSuccess: () async {
            await action(); // 로그인 성공 시 동작 실행
          },
        ),
      ),
    );
  }
}
