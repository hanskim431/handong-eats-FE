import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:handong_eats/screen/main_screen.dart';
import 'package:handong_eats/util/util.dart';
import 'package:handong_eats/util/web_socket_util.dart';
import 'package:http/http.dart' as http;

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  dynamic recentOrder;
  bool isLoading = true;
  bool isGoToStoreDone = false;
  final WebSocketUtil socketUtil = WebSocketUtil();

  @override
  void initState() {
    super.initState();
    _loadOrderHistory();
    _initializeSocketConnection();
  }

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
    final order = await _fetchRecentOrder();
    setState(() {
      recentOrder = order;
      isLoading = false;
    });
  }

  Future<dynamic> _fetchRecentOrder() async {
    const String apiUrl = 'http://127.0.0.1:3000/order/my/recent';
    final String? accessToken = await getAccessToken();

    if (accessToken == null) {
      print('AccessToken이 없습니다.');
      return null;
    }

    return await _fetchApiData(apiUrl, accessToken);
  }

  Future<dynamic> _fetchApiData(String apiUrl, String accessToken) async {
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
  Future<void> _changeOrderStatusWithLoading({
    required String orderId,
    required String orderStatus,
  }) async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    await _changeOrderStatus(orderId: orderId, orderStatus: orderStatus);
    await _loadOrderHistory();
  }

  Future<void> _changeOrderStatus({
    required String orderId,
    required String orderStatus,
  }) async {
    const String apiUrl = 'http://127.0.0.1:3000/order/status';
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
        body: jsonEncode({
          'orderId': orderId,
          'orderStatus': orderStatus,
        }),
      );

      if (response.statusCode == 200) {
        print('Order $orderStatus successfully');
        setState(() {
          recentOrder = null;
        });
      } else {
        print('Failed to $orderStatus order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _handleArrivalAtDestination() async {
    if (recentOrder != null && recentOrder['orderStatus'] == 'Delivering') {
      await _changeOrderStatusWithLoading(
        orderId: recentOrder['_id'],
        orderStatus: 'waitingAtDestination',
      );
    }
  }

  void _handleFoodReceived() {
    _changeOrderStatusWithLoading(
      orderId: recentOrder['_id'],
      orderStatus: 'Finished',
    );
    _emitReturnMessage();
  }

  void _emitReturnMessage() {
    final deliveryAddress = recentOrder['deliveryAddress'];
    const Map<String, String> returnMessages = {
      '현동홀': 'return_from_hyeondong',
      '느헤미야홀': 'return_from_nehemiah',
      '오석관': 'return_from_oseok',
    };

    final message = returnMessages[deliveryAddress];
    if (message != null) {
      socketUtil.emit('message', message);
    } else {
      print('잘못된 배달지 입니다.');
    }
  }

  Widget _buildOrderStatusUI() {
    if (recentOrder == null) {
      return const Center(child: Text('현재 주문 내역이 없습니다.'));
    }

    switch (recentOrder['orderStatus']) {
      case 'Rejected':
        return _buildDeliveryStatusUI(
          message: "주문이 거절되었습니다. 😔",
        );
      case 'Pending':
        return _buildDeliveryStatusUI(
          message: "판매자의 수락을 기다리고 있습니다. ⌛",
        );
      case 'waitingFood':
      case 'Accepted':
        return _buildDeliveryStatusUI(
          message: "음식을 기다리고 있습니다. 🍜",
          subMessage: '맛있게 만들어 드린대요!',
        );
      case 'Delivering':
        return _buildDeliveryStatusUI(
          message: "배달중이에요. 🚚",
          subMessage: '빠르게 가져다 드릴게요',
        );
      case 'waitingAtDestination':
        return _buildDeliveryStatusUI(
          message: "음식이 도착했습니다. 😋",
          subMessage: '식기전에 가져가주세요!!',
        );
      default:
        return const Center(child: Text('알 수 없는 주문 상태입니다.'));
    }
  }

  Widget _buildDeliveryStatusUI({
    required String message,
    String? subMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (subMessage != null) ...[
          const SizedBox(height: 5),
          Text(
            subMessage,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
        const SizedBox(height: 20),
        _buildRemainingTime(),
        const SizedBox(height: 10),
        _buildProgressIndicator(),
        const SizedBox(height: 20),
        Expanded(
          child: Image.asset(
            'assets/images/map.png',
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          ),
        ),
        if (recentOrder['orderStatus'] == 'waitingAtDestination')
          _buildFoodReceivedButton(),
      ],
    );
  }

  Widget _buildFoodReceivedButton() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleFoodReceived,
            child: const Text('음식 수령 완료'),
          ),
        ],
      ),
    );
  }

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
            "1분",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator({double value = 0.1}) {
    return LinearProgressIndicator(
      value: value,
      backgroundColor: Colors.grey,
      color: Colors.blue,
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
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadOrderHistory,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildOrderStatusUI(),
            ),
    );
  }
}
