import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:handong_eats/screen/home/cart_screen.dart';
import 'package:handong_eats/screen/home/home_screen.dart';
import 'package:handong_eats/screen/more/more_screen.dart';
import 'package:handong_eats/screen/order/order_tracking_screen.dart';
import 'package:handong_eats/screen/store/store_order_list_widget.dart';
import 'package:handong_eats/screen/store/store_order_screen.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // JWT 디코딩을 위한 패키지 추가

class MainScreen extends StatefulWidget {
  final int? selectedIndex;
  const MainScreen({super.key, this.selectedIndex});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int selectedIndex;
  String role = ""; // 사용자 role 변수
  final FlutterSecureStorage secureStorage =
      const FlutterSecureStorage(); // SecureStorage 인스턴스

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.selectedIndex ?? 0;
    _loadUserRole(); // 역할 정보를 불러옴
  }

  // Flutter Secure Storage에서 accessToken을 읽고 role 추출
  Future<void> _loadUserRole() async {
    String? accessToken = await secureStorage.read(key: 'accessToken');
    if (accessToken != null) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
      setState(() {
        role = decodedToken['role']; // 토큰에서 role 값 추출
      });
    }
  }

  // 사용자 role에 따른 페이지 구성
  List<Widget> get pages {
    if (role == 'store') {
      // 가게 role인 경우 주문 수락/거부 화면 추가
      return [
        const StoreOrderScreen(), // 가게가 실시간으로 주문을 처리하는 화면
        const StoreOrderHistoryScreen(),
        const MoreScreen(),
      ];
    }
    // 일반 사용자 role인 경우
    return [
      const HomeScreen(),
      const Center(child: Text('Likes Page')),
      const Center(child: Text('Search Page')),
      const OrderTrackingScreen(),
      const MoreScreen(),
    ];
  }

  // 네비게이션 바 항목 설정
  List<NavigationDestination> get navBarItems {
    if (role == 'store') {
      return [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: '홈',
        ),
        const NavigationDestination(
          icon: Icon(Icons.shopping_bag_outlined),
          selectedIcon: Icon(Icons.shopping_bag),
          label: '주문조회',
        ),
        const NavigationDestination(
          icon: Icon(Icons.menu),
          selectedIcon: Icon(Icons.menu),
          label: '더보기',
        ),
      ];
    }
    return _navBarItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: selectedIndex == 3
          ? null
          : AppBar(
              centerTitle: true,
              elevation: 2,
              shadowColor: Colors.black,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification Clicked')),
                  );
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        animationDuration: const Duration(seconds: 1),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: navBarItems,
      ),
    );
  }
}

const _navBarItems = [
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home_rounded),
    label: '홈',
  ),
  NavigationDestination(
    icon: Icon(Icons.wallet_outlined),
    selectedIcon: Icon(Icons.wallet),
    label: '쿠폰',
  ),
  NavigationDestination(
    icon: Icon(Icons.star_border_outlined),
    selectedIcon: Icon(Icons.star),
    label: '즐겨찾기',
  ),
  NavigationDestination(
    icon: Icon(Icons.shopping_bag_outlined),
    selectedIcon: Icon(Icons.shopping_bag),
    label: '주문조회',
  ),
  NavigationDestination(
    icon: Icon(Icons.menu),
    selectedIcon: Icon(Icons.menu),
    label: '더보기',
  ),
];
