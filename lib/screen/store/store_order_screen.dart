import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:handong_eats/util/util.dart'; // getAccessToken 함수 가져오기
import 'package:handong_eats/util/web_socket_util.dart'; // 웹 소켓 유틸리티 가져오기
import 'package:http/http.dart' as http;

class StoreOrderScreen extends StatefulWidget {
  const StoreOrderScreen({super.key});

  @override
  State<StoreOrderScreen> createState() => _StoreOrderScreenState();
}

class _StoreOrderScreenState extends State<StoreOrderScreen> {
  dynamic recentOrder; // 주문 내역 리스트
  bool isLoading = true; // 로딩 상태 확인
  bool isGoToStoreDone = false; // go_to_store 완료 여부
  final WebSocketUtil socketUtil = WebSocketUtil(); // 웹 소켓 유틸리티 인스턴스 생성

  @override
  void initState() {
    super.initState();
    _initializeSocketConnection();
    fetchOrderHistory(); // 화면 로드 시 주문 내역 가져오기
  }

  // 웹 소켓 연결 초기화
  void _initializeSocketConnection() {
    socketUtil.initializeSocketConnection('http://127.0.0.1:8765');

    // 서버에서 받은 'navigation_status' 메시지 처리
    socketUtil.on('navigation_status', (data) {
      print('Received navigation status: $data');
      if (data == '[go_to_store] Done') {
        setState(() {
          isGoToStoreDone = true; // 음식 탑재 완료 버튼을 활성화하기 위한 플래그 설정
        });
      }

      // 목적지 도착 후 처리
      if (data == '[go_to_hyeondong] Done' ||
          data == '[go_to_nehemiah] Done' ||
          data == '[go_to_oseok] Done') {
        _handleArrivalAtDestination();
      }
    });
  }

  // 서버에서 주문 내역을 가져오는 함수
  Future<void> fetchOrderHistory() async {
    const String apiUrl = 'http://127.0.0.1:3000/order/store/one';

    try {
      final String? accessToken = await getAccessToken(); // 토큰 가져오기
      if (accessToken == null) {
        print('AccessToken이 없습니다.');
        return;
      }

      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      });

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        setState(() {
          recentOrder = jsonDecode(response.body);
          isLoading = false; // 로딩 완료
        });
      } else {
        setState(() {
          isLoading = false; // 로딩 실패 시에도 상태 갱신
        });
        print('Failed to load order history: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false; // 에러 발생 시 로딩 상태 갱신
      });
      print('Error: $e');
    }
  }

  // 주문 상태 변경 함수
  Future<void> changeOrderStatus(String orderId, String orderStatus) async {
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

  // 목적지 도착 후 처리
  Future<void> _handleArrivalAtDestination() async {
    await fetchOrderHistory(); // 현재 주문 내역을 다시 가져오기

    if (recentOrder != null && recentOrder['orderStatus'] == 'Delivering') {
      // 주문 상태가 Delivering이면 상태를 waitingAtDestination으로 변경
      changeOrderStatus(recentOrder['_id'], 'waitingAtDestination');
    }
  }

  // 음식 탑재 완료 로직
  void handleFoodLoaded() {
    changeOrderStatus(recentOrder['_id'], 'Delivering');

    final deliveryAddress = recentOrder['deliveryAddress'];
    switch (deliveryAddress) {
      case '현동홀':
        socketUtil.emit('message', 'go_to_hyeondong');
        break;
      case '느헤미야홀':
        socketUtil.emit('message', 'go_to_nehemiah');
        break;
      case '오석관':
        socketUtil.emit('message', 'go_to_oseok');
        break;
      default:
        print('잘못된 배달지 입니다.');
    }
  }

  // 주문 처리 버튼 생성 함수
  Widget buildOrderActions() {
    if (recentOrder['orderStatus'] == 'Finish') {
      return const Text("완료된 주문 건 입니다.");
    } else if (recentOrder['orderStatus'] == 'Pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              changeOrderStatus(recentOrder['_id'], 'Accepted');
              socketUtil.emit('message', 'go_to_store');
            },
            child: const Text('주문 수락'),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              changeOrderStatus(recentOrder['_id'], 'Rejected');
            },
            child: const Text('주문 거부'),
          ),
        ],
      );
    } else if (recentOrder['orderStatus'] == 'Accepted' && isGoToStoreDone) {
      // go_to_store가 완료된 경우에만 버튼 활성화
      return Center(
        child: ElevatedButton(
          onPressed: handleFoodLoaded,
          child: const Text('음식 탑재 완료'),
        ),
      );
    } else if (recentOrder['orderStatus'] == 'Accepted' && !isGoToStoreDone) {
      return Center(
        child: ElevatedButton(
          onPressed: () {},
          child: const Text('아직 로봇이 오고 있어요'),
        ),
      );
    }
    return Container();
  }

  @override
  void dispose() {
    socketUtil.dispose(); // 소켓 연결 해제 및 자원 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('실시간 주문 처리'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              setState(() {
                isLoading = true; // 로딩 상태로 전환
              });
              fetchOrderHistory(); // 주문 내역 다시 불러오기
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recentOrder == null
              ? const Center(child: Text('대기 중인 주문이 없습니다.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 주문 정보 표시
                      Text(
                        '주문 상태: ${recentOrder['orderStatus']}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '배달지: ${recentOrder['deliveryAddress']}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text('주문자: ${recentOrder['userId']}'),
                      const SizedBox(height: 10),
                      Text('주문시간: ${recentOrder['createdAt']}'),
                      const SizedBox(height: 30),
                      const Text(
                        '상품:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 5),
                      ...recentOrder['cartItems'].map<Widget>((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                              '${item['menuName']} x ${item['amount']} - ${item['cost']}원'),
                        );
                      }).toList(),
                      const SizedBox(height: 10),
                      Text('총 결제 금액: ${recentOrder['totalCost']}원',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 20),
                      buildOrderActions(),
                    ],
                  ),
                ),
    );
  }
}
