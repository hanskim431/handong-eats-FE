import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:handong_eats/util/util.dart';
import 'package:http/http.dart' as http;

class StoreOrderHistoryScreen extends StatefulWidget {
  const StoreOrderHistoryScreen({super.key});

  @override
  _StoreOrderHistoryScreenState createState() =>
      _StoreOrderHistoryScreenState();
}

class _StoreOrderHistoryScreenState extends State<StoreOrderHistoryScreen> {
  int currentPage = 1;
  int itemsPerPage = 5; // 한 페이지에 표시할 주문 수 (5개로 설정)
  List<dynamic> orderHistory = []; // 주문 내역 리스트
  bool isLoading = true; // 로딩 상태 확인

  @override
  void initState() {
    super.initState();
    fetchOrderHistory(); // 화면 로드 시 주문 내역 가져오기
  }

  // 서버에서 주문 내역을 가져오는 함수
  Future<void> fetchOrderHistory() async {
    const String apiUrl = 'http://10.0.2.2:3000/order/store';

    try {
      final String? accessToken = await getAccessToken();

      if (accessToken == null) {
        print('AccessToken이 없습니다.');
        return;
      }

      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      });

      if (response.statusCode == 200) {
        final List<dynamic> orders = jsonDecode(response.body);
        setState(() {
          orderHistory = orders; // 주문 내역 저장
          isLoading = false; // 로딩 완료
        });
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

  // 현재 페이지에 표시할 주문 내역 리스트 반환
  List<dynamic> getCurrentPageItems() {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    return orderHistory.sublist(startIndex,
        endIndex > orderHistory.length ? orderHistory.length : endIndex);
  }

  // MongoDB의 $date 필드를 DateTime으로 변환
  DateTime _convertDate(dynamic dateField) {
    if (dateField is Map && dateField.containsKey('\$date')) {
      final dateValue = dateField['\$date'];
      if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }
    }
    return DateTime.now(); // 기본적으로 현재 시간을 반환하도록 함
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 내역'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중 표시
          : orderHistory.isEmpty
              ? const Center(child: Text('주문 내역이 없습니다.')) // 주문 내역이 없을 때
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: getCurrentPageItems().length,
                        itemBuilder: (context, index) {
                          final order = getCurrentPageItems()[index];

                          // 주문 날짜 변환
                          final DateTime createdAt =
                              _convertDate(order['createdAt']);

                          // 주문 내역을 표시할 카드 위젯
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '주문일시: ${createdAt.toString()}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 5),
                                  Text('주문 상태: ${order['orderStatus']}'),
                                  Text('주문자: ${order['userId']}'),
                                  Text('수령지: ${order['deliveryAddress']}'),
                                  Text('결제 금액: ${order['totalCost']}원'),
                                  const SizedBox(height: 5),
                                  const Text(
                                    '메뉴 목록:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  for (var item in order['cartItems'])
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2.0),
                                      child: Text(
                                        '${item['menuName']} x ${item['amount']} - ${item['cost']}원',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // 페이지네이션 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: currentPage > 1
                              ? () {
                                  setState(() {
                                    currentPage--;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Text('$currentPage'),
                        IconButton(
                          onPressed:
                              (currentPage * itemsPerPage) < orderHistory.length
                                  ? () {
                                      setState(() {
                                        currentPage++;
                                      });
                                    }
                                  : null,
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
