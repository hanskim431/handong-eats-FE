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
  dynamic recentOrder;
  bool isLoading = true;
  bool isGoToStoreDone = false;
  final WebSocketUtil socketUtil = WebSocketUtil();

  @override
  void initState() {
    super.initState();
    _initializeSocketConnection();
    _loadOrderHistory();
  }

  // 웹 소켓 연결 초기화
  void _initializeSocketConnection() {
    socketUtil.initializeSocketConnection('http://127.0.0.1:8765');
    socketUtil.on('navigation_status', (data) {
      _handleNavigationStatus(data);
    });
  }

  void _handleNavigationStatus(String data) {
    print('Received navigation status: $data');
    if (data == '[go_to_store] Done') {
      setState(() {
        isGoToStoreDone = true;
      });
    } else if (data.contains('Done')) {
      _handleArrivalAtDestination();
    }
  }

  Future<void> _loadOrderHistory() async {
    setState(() => isLoading = true);
    final order = await _fetchOrderFromServer();
    setState(() {
      recentOrder = order;
      isLoading = false;
    });
  }

  Future<dynamic> _fetchOrderFromServer() async {
    const apiUrl = 'http://127.0.0.1:3000/order/store/one';
    final String? accessToken = await getAccessToken();
    if (accessToken == null) {
      print('AccessToken이 없습니다.');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return jsonDecode(response.body);
      } else {
        print('Failed to load order history: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  // 주문 상태 변경 함수 (로딩 상태 포함)
  Future<void> _changeOrderStatusWithLoading(
      String orderId, String status) async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // 1초 로딩 시간 추가
    await _changeOrderStatus(orderId, status);
    await _loadOrderHistory(); // 상태 변경 후 주문 내역 다시 로드
  }

  Future<void> _changeOrderStatus(String orderId, String status) async {
    const apiUrl = 'http://127.0.0.1:3000/order/status';
    final String? accessToken = await getAccessToken();

    if (accessToken == null) {
      print('AccessToken이 없습니다.');
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'orderId': orderId, 'orderStatus': status}),
      );
      if (response.statusCode != 200) {
        print('Failed to $status order: ${response.statusCode}');
        print('message: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _handleArrivalAtDestination() async {
    if (recentOrder != null && recentOrder['orderStatus'] == 'Delivering') {
      await _changeOrderStatusWithLoading(
          recentOrder['_id'], 'waitingAtDestination');
    }
  }

  void _handleFoodLoaded() {
    _changeOrderStatusWithLoading(recentOrder['_id'], 'Delivering');
    _emitDeliveryLocation();
  }

  void _emitDeliveryLocation() {
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
        print('잘못된 배달지입니다.');
    }
  }

  // 주문 처리 버튼 생성 함수
  Widget _buildOrderActions() {
    switch (recentOrder['orderStatus']) {
      case 'Finish':
        return const Text("완료된 주문 건 입니다.");
      case 'Pending':
        return _buildPendingActions();
      case 'Accepted':
        return isGoToStoreDone
            ? _buildFoodLoadedButton()
            : _buildAwaitingRobotButton();
      default:
        return Container();
    }
  }

  Widget _buildPendingActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            _changeOrderStatusWithLoading(recentOrder['_id'], 'Accepted');
            socketUtil.emit('message', 'go_to_store');
          },
          child: const Text('주문 수락'),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () {
            _changeOrderStatusWithLoading(recentOrder['_id'], 'Rejected');
          },
          child: const Text('주문 거부'),
        ),
      ],
    );
  }

  Widget _buildFoodLoadedButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _handleFoodLoaded,
        child: const Text('음식 탑재 완료'),
      ),
    );
  }

  Widget _buildAwaitingRobotButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {},
        child: const Text('아직 로봇이 오고 있어요'),
      ),
    );
  }

  @override
  void dispose() {
    socketUtil.dispose();
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
            onPressed: _loadOrderHistory,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recentOrder == null
              ? const Center(child: Text('대기 중인 주문이 없습니다.'))
              : _buildOrderDetails(),
    );
  }

  Widget _buildOrderDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderInfo(),
          const SizedBox(height: 30),
          _buildOrderItems(),
          const SizedBox(height: 10),
          Text('총 결제 금액: ${recentOrder['totalCost']}원',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          _buildOrderActions(),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '주문 상태: ${recentOrder['orderStatus']}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          '배달지: ${recentOrder['deliveryAddress']}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text('주문자: ${recentOrder['userId']}'),
        const SizedBox(height: 10),
        Text('주문시간: ${recentOrder['createdAt']}'),
      ],
    );
  }

  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('상품:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        ...recentOrder['cartItems'].map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
                '${item['menuName']} x ${item['amount']} - ${item['cost']}원'),
          );
        }).toList(),
      ],
    );
  }
}
