import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:handong_eats/screen/order/place_select_screen.dart';
import 'package:handong_eats/screen/main_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
    _loadCartItems();
  }

  void _loadCartItems() {
    List<String>? savedCartItems = prefs?.getStringList('cart');
    if (savedCartItems != null) {
      cartItems = savedCartItems
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList();
    }
    setState(() {});
  }

  Future<void> _updateCart() async {
    List<String> updatedCart =
        cartItems.map((item) => jsonEncode(item)).toList();
    await prefs?.setStringList('cart', updatedCart);
  }

  Future<void> _deleteCartItem(int index) async {
    cartItems.removeAt(index);
    _updateCart();
    setState(() {});
  }

  Future<void> _clearCart() async {
    cartItems.clear();
    await prefs?.remove('cart');
    setState(() {});
  }

  // 총 가격을 계산하는 함수
  int _calculateTotalCost() {
    return cartItems.fold(0, (total, item) {
      return total + (item['cost'] as int) * (item['amount'] as int);
    });
  }

  // 수량을 변경하는 함수
  void _updateAmount(int index, int change) {
    setState(() {
      cartItems[index]['amount'] += change;
      if (cartItems[index]['amount'] < 1) {
        cartItems[index]['amount'] = 1;
      }
    });
    _updateCart(); // 변경된 수량을 저장
  }

  @override
  Widget build(BuildContext context) {
    bool isCartEmpty = cartItems.isEmpty;
    int totalCost = _calculateTotalCost(); // 총 금액 계산

    print(cartItems);

    return Scaffold(
      appBar: AppBar(
        title: const Text("장바구니"),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.black,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearCart, // 전체 삭제 기능
          ),
        ],
      ),
      body: isCartEmpty
          ? const Center(
              child: Text(
                "장바구니가 비어 있습니다.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                child: Column(
                  children: List.generate(cartItems.length, (index) {
                    final item = cartItems[index];

                    // 옵션이 있는지 확인하고 형식에 맞게 옵션 텍스트 구성
                    Widget optionsWidget = const Text(
                      '추가 선택 X',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    );

                    if (item.containsKey('options') &&
                        item['options'] != null) {
                      List<dynamic> options = item['options'];
                      if (options.isNotEmpty) {
                        optionsWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: options.map<Widget>((option) {
                            String descriptionText =
                                option.containsKey('description')
                                    ? ' (${option['description']})'
                                    : '';
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    '${option['name']}$descriptionText',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ),
                                Text(
                                  '+${option['cost']}원',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            );
                          }).toList(),
                        );
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 15),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 1.0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${item['cost']}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const Text(
                                    ' 원',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // 옵션을 포맷된 텍스트로 출력
                          optionsWidget,
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    _deleteCartItem(index), // 아이템 삭제 기능
                                child: const Text('삭제'),
                              ),
                              Row(
                                children: [
                                  OutlinedButton(
                                    onPressed: () =>
                                        _updateAmount(index, -1), // 수량 감소
                                    child: const Text('-'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Text('${item['amount']}'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () =>
                                        _updateAmount(index, 1), // 수량 증가
                                    child: const Text('+'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min, // 세로 방향으로 최소 공간 차지
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '합계',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Text(
                      '$totalCost',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff012B6E),
                      ),
                    ),
                    const Text(
                      ' 원',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff012B6E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 70, // 버튼의 고정 높이 설정
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      color: const Color(0XFFAEAEAE),
                      child: const Center(
                        child: Text(
                          '추가 주문하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: isCartEmpty
                        ? null // 장바구니가 비어있으면 클릭 불가
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PlaceSelectScreen(),
                              ),
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      color:
                          isCartEmpty ? Colors.grey : const Color(0XFF005C99),
                      child: const Center(
                        child: Text(
                          '결제하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
