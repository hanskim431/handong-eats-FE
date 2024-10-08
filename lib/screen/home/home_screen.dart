import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, String>> foodItems = const [
    {'image': 'assets/images/whopper.png', 'name': '와퍼'},
    {'image': 'assets/images/whopper.png', 'name': '와퍼 주니어'},
    {'image': 'assets/images/tteokbokki.jpg', 'name': '갓만든 떡볶이'},
    {'image': 'assets/images/tteokbokki.jpg', 'name': '짜장 떡볶이'},
    {'image': 'assets/images/jae-yuk.jpg', 'name': '제육덮밥'},
    {'image': 'assets/images/sushi.jpg', 'name': '초밥'},
    {'image': 'assets/images/chicken-salad.jpg', 'name': '닭가슴살 샐러드'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        itemCount: foodItems.length,
        itemBuilder: (context, index) {
          final foodItem = foodItems[index];
          final imagePath = foodItem['image']!;

          // 클릭 가능한 항목 결정
          bool isClickable = index < 2;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: GestureDetector(
                onTap: isClickable
                    ? () {
                        // 클릭 가능한 항목에서 클릭 이벤트 처리
                        print("클릭된 항목: ${foodItem['name']}");
                      }
                    : null, // 비클릭 항목에서는 아무 동작도 하지 않음
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      height: 100,
                      width: 100,
                      // 이미지에 컬러 필터 적용
                      child: ColorFiltered(
                        colorFilter: isClickable
                            ? const ColorFilter.mode(
                                Colors.transparent, BlendMode.multiply)
                            : const ColorFilter.mode(
                                Colors.grey, BlendMode.saturation), // 흑백 필터
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.fastfood_outlined,
                            size: 80,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      foodItem['name']!,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: isClickable
                            ? Colors.black
                            : Colors.grey, // 클릭 가능 여부에 따른 텍스트 색상 변경
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
