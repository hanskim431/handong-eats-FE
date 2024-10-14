import 'package:flutter/material.dart';
import 'package:handong_eats/screen/main_screen.dart';
import 'package:handong_eats/screen/order/widget/order_tracking_widget.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

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
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // 도움말 버튼 클릭 시 기능
            },
          ),
        ],
      ),
      body: const OrderTrackingWidget(),
    );
  }
}
