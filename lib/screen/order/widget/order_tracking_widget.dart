import 'package:flutter/material.dart';

class OrderTrackingWidget extends StatelessWidget {
  const OrderTrackingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "가고 있습니다.",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            "시장이 반찬입니다.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
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
                  "21분",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const LinearProgressIndicator(
            value: 0.7, // 남은 시간에 따라 조정
            backgroundColor: Colors.grey,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          DropdownButton<String>(
            isExpanded: true,
            value: "주문 조회",
            items: const [
              DropdownMenuItem(
                value: "주문 조회",
                child: Text("주문 조회"),
              ),
              DropdownMenuItem(
                value: "배달 추적",
                child: Text("배달 추적"),
              ),
            ],
            onChanged: (String? newValue) {
              // 드롭다운 변경 처리
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              color: Colors.grey[300], // 지도 이미지 대신 회색 박스
              child: const Center(
                child: Text("지도 이미지"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
