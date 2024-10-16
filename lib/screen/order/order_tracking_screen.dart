import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:handong_eats/screen/main_screen.dart';
import 'package:handong_eats/util/util.dart';
import 'package:http/http.dart' as http;

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  dynamic recentOrder; // 주문 내역 리스트
  bool isLoading = true; // 로딩 상태 확인

  // 서버에서 주문 내역을 가져오는 함수
  Future<void> fetchOrderHistory() async {
    const String apiUrl = 'http://127.0.0.1:3000/order/my/recent';

    try {
      final String? accessToken = await getAccessToken(); // util에서 토큰 가져오기

      if (accessToken == null) {
        print('AccessToken이 없습니다.');
        return;
      }

      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      });

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final dynamic order = jsonDecode(response.body);
          print(order);
          setState(() {
            recentOrder = order; // 주문 내역 저장
            isLoading = false; // 로딩 완료
          });
        }
      } else {
        print('Failed to load order history: ${response.statusCode}');
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

  // 주문 상태 변경 함수
  Future<void> changeOrderstatus({
    required String orderId,
    required String orderStatus,
  }) async {
    const String apiUrl = 'http://127.0.0.1:3000/order/status'; // 주문 수락 API

    try {
      final String? accessToken = await getAccessToken();

      if (accessToken == null) {
        print('AccessToken이 없습니다.');
        return;
      }

      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'orderId': orderId,
          'orderStatus': orderStatus,
        }),
      );

      if (response.statusCode == 200) {
        print('Order $orderStatus successfully');
        setState(() {
          recentOrder = null; // 주문 처리 후 초기화
        });
      } else {
        print('Failed to $orderStatus order: ${response.statusCode}');
        print('message: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOrderHistory(); // 화면 로드 시 주문 내역 가져오기
  }

  // 주문 상태에 따른 UI 출력
  Widget _buildOrderStatusUI() {
    if (recentOrder == null) {
      return const Center(
        child: Text('현재 주문 내역이 없습니다.'),
      );
    }

    switch (recentOrder['orderStatus']) {
      case 'Rejected':
        return _buildDeliveryUI(
          message: "주문이 거절되었습니다. 😔",
        );
      case 'Pending':
        return _buildDeliveryUI(
          message: "판매자의 수락을 기다리고 있습니다. ⌛",
        );
      case 'waitingFood':
      case 'Accepted':
        return _buildDeliveryUI(
          message: "음식을 기다리고 있습니다. 🍜",
          subMessage: '맛있게 만들어 드린대요!',
        );
      case 'Delivering':
        return _buildDeliveryUI(
          message: "배달중이에요. 🚚",
          subMessage: '빠르게 가져다 드릴게요',
        );
      case 'waitingAtDestination':
        return _buildDeliveryUI(
          message: "음식이 도착했습니다. 😋",
          subMessage: '식기전에 가져가주세요!!',
        );
      default:
        return const Center(child: Text('알 수 없는 주문 상태입니다.'));
    }
  }

  // 배달 진행 중인 경우 UI
  Widget _buildDeliveryUI({required String message, String? subMessage}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        (subMessage != null)
            ? Text(
                subMessage,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              )
            : const Text(
                '',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
        const SizedBox(height: 20),
        _buildRemainingTime(),
        const SizedBox(height: 10),
        _buildProgressIndicator(),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            color: Colors.grey[300], // 지도 이미지 대신 회색 박스
            child: const Center(
              child: Text("지도 이미지"),
            ),
          ),
        ),
        if (recentOrder['orderStatus'] == 'waitingAtDestination')
          Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    changeOrderstatus(
                      orderId: recentOrder['_id'],
                      orderStatus: 'Finished',
                    );
                  },
                  child: const Text('음식 수령 완료'),
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 100)
      ],
    );
  }

  // 남은 시간 UI
  Widget _buildRemainingTime() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "남은 시간",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "21분",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // 진행 바
  Widget _buildProgressIndicator({double value = 0.1}) {
    return LinearProgressIndicator(
      value: value, // 남은 시간에 따라 조정
      backgroundColor: Colors.grey,
      color: Colors.blue,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("주문 조회"),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.black,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MainScreen(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // 도움말 버튼 클릭 시 기능
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중일 때
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildOrderStatusUI(),
            ),
    );
  }
}
