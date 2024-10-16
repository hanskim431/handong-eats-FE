import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:handong_eats/util/util.dart'; // util.dart 파일에서 getAccessToken 가져옴
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class StoreOrderScreen extends StatefulWidget {
  const StoreOrderScreen({super.key});

  @override
  State<StoreOrderScreen> createState() => _StoreOrderScreenState();
}

class _StoreOrderScreenState extends State<StoreOrderScreen> {
  dynamic recentOrder; // 주문 내역 리스트
  bool isLoading = true; // 로딩 상태 확인

  @override
  void initState() {
    super.initState();
    fetchOrderHistory(); // 화면 로드 시 주문 내역 가져오기
  }

  // 서버에서 주문 내역을 가져오는 함수
  Future<void> fetchOrderHistory() async {
    const String apiUrl = 'http://127.0.0.1:3000/order/store/one';

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
        if (response.body != '') {
          final dynamic order = jsonDecode(response.body);
          recentOrder = order; // 주문 내역 저장
        }
        setState(() {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('실시간 주문 처리'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중일 때
          : recentOrder == null
              ? const Center(child: Text('대기 중인 주문이 없습니다.')) // 주문이 없을 때
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
                      Text(
                        '주문자: ${recentOrder['userId']}',
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '주문시간: ${recentOrder['createdAt']}',
                      ),
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

                      // 버튼 섹션
                      if (recentOrder['orderStatus'] == 'Accepted')
                        // Accepted 상태일 때: 음식 탑재 완료 버튼 표시
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              // 음식 탑재 완료 처리
                              changeOrderstatus(
                                orderId: recentOrder['_id'],
                                orderStatus: 'Delivering',
                              );
                            },
                            child: const Text('음식 탑재 완료'),
                          ),
                        )
                      else if (recentOrder['orderStatus'] == 'Pending')
                        // Accepted가 아닐 때: 주문 수락 및 주문 거부 버튼 표시
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // 수락 버튼 로직
                                changeOrderstatus(
                                  orderId: recentOrder['_id'],
                                  orderStatus: 'Accepted',
                                );
                              },
                              child: const Text('주문 수락'),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: () {
                                changeOrderstatus(
                                  orderId: recentOrder['_id'],
                                  orderStatus: 'Rejected',
                                );
                              },
                              child: const Text('주문 거부'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }
}
