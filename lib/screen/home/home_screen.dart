import 'package:flutter/material.dart';
import 'package:handong_eats/screen/home/widget/menu_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // bad code :: must save in back-end
  final List<Map<String, dynamic>> foodItems = const [
    {
      'menuId': 'menu_01',
      'image': 'assets/images/whopper.png',
      'name': '와퍼',
      'cost': 6700,
      'storeId': 'bugerking',
      'storeName': '버거킹',
      'amount': 1,
      'options': [
        {'name': '세트업', 'description': '콜라, 감자튀김', 'cost': 2000},
        {'name': '페티 추가', 'cost': 500},
      ],
    },
    {
      'menuId': 'menu_02',
      'image': 'assets/images/whopper.png',
      'name': '와퍼 주니어',
      'cost': 5700,
      'storeId': 'bugerking',
      'storeName': '버거킹',
      'amount': 1,
      'options': [
        {'name': '세트업', 'description': '콜라, 감자튀김', 'cost': 2000},
      ],
    },
    {
      'menuId': 'menu_03',
      'image': 'assets/images/tteokbokki.jpg',
      'name': '갓만든 떡볶이',
      'cost': 4000,
      'amount': 1,
      'storeId': 'bunsick',
      'storeName': '분식',
      'options': [
        {'name': '튀김 추가', 'description': '오징어 튀김, 감자 튀김', 'cost': 2000},
        {'name': '치즈 추가', 'cost': 2000},
      ],
    },
    {
      'menuId': 'menu_04',
      'image': 'assets/images/tteokbokki.jpg',
      'name': '짜장 떡볶이',
      'storeName': '분식',
      'cost': 4000,
      'storeId': 'bunsick',
      'amount': 1,
    },
    {
      'menuId': 'menu_05',
      'image': 'assets/images/jae-yuk.jpg',
      'name': '제육덮밥',
      'cost': 5000,
      'storeId': 'bob',
      'storeName': '따스한동',
      'amount': 1,
    },
    {
      'menuId': 'menu_06',
      'image': 'assets/images/sushi.jpg',
      'name': '초밥',
      'cost': 9000,
      'storeId': 'bob',
      'storeName': '따스한동',
      'amount': 1,
    },
    {
      'menuId': 'menu_07',
      'image': 'assets/images/chicken-salad.jpg',
      'name': '닭가슴살 샐러드',
      'cost': 6700,
      'storeId': 'salad',
      'storeName': '샐러디',
      'amount': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        itemCount: foodItems.length,
        itemBuilder: (context, index) {
          final foodItem = foodItems[index];

          bool isClickable = index < 2;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: MenuWidget(
              foodItem: foodItem,
              isClickable: isClickable,
            ),
          );
        },
      ),
    );
  }
}
