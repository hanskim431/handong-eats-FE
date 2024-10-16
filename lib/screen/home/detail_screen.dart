import 'dart:convert'; // JSON 인코딩/디코딩에 필요

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:handong_eats/screen/home/cart_screen.dart';
import 'package:handong_eats/screen/main_screen.dart';
import 'package:handong_eats/util/util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> foodItem;

  const DetailScreen({
    super.key,
    required this.foodItem,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  List<bool> optionSelections = []; // 옵션 체크박스 상태를 저장할 리스트
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    _initializePreferences();

    // 옵션 리스트가 있다면 옵션 선택 초기화
    if (widget.foodItem['options'] != null) {
      optionSelections =
          List<bool>.filled(widget.foodItem['options'].length, false);
    }
  }

  // SharedPreferences 초기화
  Future<void> _initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {}); // prefs 초기화 후 상태 갱신
  }

  // 장바구니에 메뉴를 담는 함수
  Future<void> addToCart() async {
    // 초기화가 완료되기 전에 addToCart가 호출되지 않도록 확인
    if (prefs == null) {
      return; // 아직 초기화되지 않았다면 아무 작업도 하지 않음
    }

    // 기존 장바구니 가져오기
    List<String> cartItems = prefs!.getStringList('cart') ?? [];

    // 추가 옵션 비용 계산
    int additionalCost = 0;
    List<Map<String, dynamic>> selectedOptions = [];
    if (widget.foodItem['options'] != null) {
      for (int i = 0; i < optionSelections.length; i++) {
        if (optionSelections[i]) {
          additionalCost += widget.foodItem['options'][i]['cost'] as int;
          selectedOptions.add(widget.foodItem['options'][i]);
        }
      }
    }

    // 선택된 메뉴 정보
    Map<String, dynamic> cartItem = {
      'menuId': widget.foodItem['menuId'],
      'storeId': widget.foodItem['storeId'],
      'storeName': widget.foodItem['storeName'],
      'name': widget.foodItem['name'],
      'cost': widget.foodItem['cost'] + additionalCost,
      'options': selectedOptions,
      'amount': 1, // 처음에 추가될 때 amount는 1
    };

    // 중복된 상품이 있는지 확인
    bool itemExists = false;
    for (int i = 0; i < cartItems.length; i++) {
      Map<String, dynamic> existingItem = jsonDecode(cartItems[i]);

      // 옵션 리스트를 정렬하여 순서가 달라도 같은 것으로 인식
      List<Map<String, dynamic>> existingOptions =
          List<Map<String, dynamic>>.from(existingItem['options']);
      List<Map<String, dynamic>> newOptions =
          List<Map<String, dynamic>>.from(cartItem['options']);

      existingOptions.sort((a, b) => a['name'].compareTo(b['name']));
      newOptions.sort((a, b) => a['name'].compareTo(b['name']));

      // 상품 이름과 정렬된 옵션 리스트가 모두 같을 경우에 수량만 증가
      if (existingItem['name'] == cartItem['name'] &&
          const DeepCollectionEquality().equals(existingOptions, newOptions)) {
        existingItem['amount'] += 1; // 수량 증가
        cartItems[i] = jsonEncode(existingItem); // 기존 아이템 업데이트
        itemExists = true;
        break;
      }
    }

    // 중복된 상품이 없으면 새로 추가
    if (!itemExists) {
      cartItems.add(jsonEncode(cartItem));
    }

    // 장바구니 저장
    await prefs!.setStringList('cart', cartItems);
  }

  @override
  Widget build(BuildContext context) {
    final foodName = widget.foodItem['name'];
    final foodImage = widget.foodItem['image'];
    final foodCost = widget.foodItem['cost'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("상세정보"),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.black,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: prefs == null // 초기화가 완료되지 않았을 경우 로딩 상태를 보여줌
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이미지 부분
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          foodImage,
                          fit: BoxFit.cover,
                          height: 200, // 이미지 높이 조정
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.fastfood_outlined,
                            size: 80,
                          ),
                        ),
                      ),
                    ),
                    // 음식 이름과 가격
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        child: Center(
                          child: Text(
                            foodName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 가격 정보
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '가격',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${foodCost + optionSelections.asMap().entries.fold(0, (total, entry) => total + (entry.value ? (widget.foodItem['options']?[entry.key]['cost'] as int) : 0))} 원',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 추가 선택 (옵션이 있는 경우만)
                    if (widget.foodItem['options'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '추가 선택',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          ...List<Widget>.generate(
                            widget.foodItem['options'].length,
                            (index) {
                              final option = widget.foodItem['options'][index];
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: optionSelections[index],
                                        onChanged: (bool? value) {
                                          setState(() {
                                            optionSelections[index] =
                                                value ?? false;
                                          });
                                        },
                                      ),
                                      Text(option['name']),
                                    ],
                                  ),
                                  Text(
                                    '+${option['cost'].toString()} 원',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SizedBox(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () async {
                  checkLoginAndExecute(context, () async {
                    await addToCart();
                    // 홈 화면으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                    );
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    color: Color(0XFFAEAEAE),
                  ),
                  child: const Center(
                    child: Text(
                      '장바구니 담기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () async {
                  checkLoginAndExecute(context, () async {
                    await addToCart();
                    // 장바구니 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    color: Color(0XFF005C99),
                  ),
                  child: const Center(
                    child: Text(
                      '주문하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
