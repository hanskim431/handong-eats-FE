import 'dart:convert'; // JSON 인코딩을 위해 필요
import 'package:flutter/material.dart';
import 'package:handong_eats/screen/main_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // FlutterSecureStorage 패키지 추가

class PlaceSelectScreen extends StatefulWidget {
  const PlaceSelectScreen({super.key});

  @override
  State<PlaceSelectScreen> createState() => _PlaceSelectScreenState();
}

class _PlaceSelectScreenState extends State<PlaceSelectScreen> {
  String selectedAddress = "느헤미야홀"; // 선택된 배달지 기본값
  SharedPreferences? prefs;
  final FlutterSecureStorage secureStorage =
      const FlutterSecureStorage(); // SecureStorage 인스턴스 생성

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  // 알림창을 띄우는 함수
  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // SharedPreferences 초기화
  Future<void> _initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {}); // prefs 초기화 후 상태 갱신
  }

  // FlutterSecureStorage에서 accessToken을 가져오는 함수
  Future<String?> _getAccessToken() async {
    return await secureStorage.read(key: 'accessToken'); // accessToken을 가져옴
  }

  // 장바구니 데이터를 SharedPreferences에서 가져오는 함수
  Future<List<Map<String, dynamic>>> _getCartItems() async {
    if (prefs == null) return [];

    // SharedPreferences에서 'cart' 가져오기
    List<String> cartItemsString = prefs!.getStringList('cart') ?? [];

    // 각 항목을 디코딩하여 JSON으로 변환
    List<Map<String, dynamic>> cartItems = cartItemsString
        .map((item) => json.decode(item) as Map<String, dynamic>)
        .toList();

    return cartItems;
  }

  // 백엔드로 주문 데이터 전송하는 함수
  Future<void> submitOrder() async {
    const String apiUrl = 'http://127.0.0.1:3000/order'; // 백엔드 주소

    // 장바구니 데이터를 SharedPreferences에서 가져오기
    List<Map<String, dynamic>> cartItems = await _getCartItems();

    if (cartItems.isEmpty) {
      print('장바구니가 비어 있습니다.');
      return;
    }

    // 총 가격 계산
    int totalCost = cartItems.fold(0,
        (sum, item) => sum + ((item['cost'] as int) * (item['amount'] as int)));

    // 주문 정보 구성
    final orderData = {
      'storeId': cartItems[0]['storeId'],
      'deliveryAddress': selectedAddress, // 선택된 배달지 주소
      'cartItems': cartItems
          .map((item) => {
                'menuName': item['name'],
                'amount': item['amount'],
                'options': (item['options'] as List<dynamic>).map((option) {
                  return {
                    'name': option['name'],
                    'description': option['description'] ?? '',
                    'cost': option['cost'],
                  };
                }).toList(), // 옵션이 리스트로 변환됨
                'cost': item['cost'],
              })
          .toList(), // 장바구니 아이템
      'totalCost': totalCost, // 총 가격
    };

    final String? accessToken = await _getAccessToken();

    if (accessToken == null) {
      print('AccessToken이 없습니다.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $accessToken', // SecureStorage에서 가져온 accessToken
        },
        body: json.encode(orderData), // JSON 데이터 변환
      );

      if (response.statusCode == 201) {
        print('Order submitted successfully!');
        // 주문 성공 시 다른 화면으로 이동할 수 있습니다.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreen(selectedIndex: 3),
          ),
        );
      } else if (response.statusCode == 400) {
        // 결제 실패 또는 포인트 부족 상황 처리
        final responseBody = json.decode(response.body);
        print(responseBody);
        if (responseBody['message']
            .toString()
            .contains('payment.payCost-leak of points')) {
          _showAlertDialog('결제 실패', '포인트가 부족합니다.');
        } else {
          _showAlertDialog('결제 실패', '알 수 없는 문제가 발생했습니다.');
        }
      } else {
        print('Failed to submit order: ${response.statusCode}');
        print('Error message: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // 배송지 이름과 위치 정보를 저장한 리스트
  final List<Map<String, dynamic>> deliveryPoints = [
    {"name": "느헤미야홀", "position": const Offset(100, 120)},
    {"name": "뉴턴홀", "position": const Offset(200, 150)},
    {"name": "한동대학교", "position": const Offset(150, 200)},
    {"name": "올네이션스홀", "position": const Offset(250, 250)},
    {"name": "아이작홀", "position": const Offset(300, 100)},
  ];

  // 클릭 시 선택된 배송지를 변경하는 함수
  void selectAddress(String address) {
    setState(() {
      selectedAddress = address;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("배송지 선택"),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.black,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "배송지 선택",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              // Stack 위젯을 사용해 지도 위에 클릭 가능한 포인트 배치
              Stack(
                children: [
                  // 지도 이미지
                  Image.asset(
                    'assets/images/map.png', // 실제 학교 지도 이미지 경로로 변경하세요
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                  // 포인트들을 반복해서 지도에 배치
                  for (var point in deliveryPoints)
                    Positioned(
                      left: point['position'].dx,
                      top: point['position'].dy,
                      child: GestureDetector(
                        onTap: () {
                          selectAddress(point['name']);
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              point['name'][0], // 포인트 이름의 첫 글자만 표시
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "선택된 배송지: $selectedAddress",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "주문 요청 사항",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: "가게에 요청사항을 입력해주세요\n(예. 단무지 빼주세요)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              Center(
                child: SizedBox(
                  width: double.infinity, // 버튼이 가로로 화면을 채우게 함
                  child: ElevatedButton(
                    onPressed: submitOrder, // 결제하기 버튼을 누르면 주문 전송
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005C99), // 버튼 배경색
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "결제하기",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
