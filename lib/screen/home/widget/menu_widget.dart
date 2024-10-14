import 'package:flutter/material.dart';
import 'package:handong_eats/screen/home/detail_screen.dart';

const double kImageHeight = 100;
const double kImageWidth = 100;
const double kPaddingHorizontal = 20;
const double kPaddingVertical = 5;
const double kBorderRadius = 10;
const double kFoodNameFontSize = 30;
const FontWeight kFoodNameFontWeight = FontWeight.bold;

class MenuWidget extends StatelessWidget {
  const MenuWidget({
    super.key,
    required this.foodItem,
    required this.isClickable,
  });

  final Map<String, dynamic> foodItem;
  final bool isClickable;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isClickable
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(
                    foodItem: foodItem,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(kBorderRadius)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: kPaddingHorizontal,
          vertical: kPaddingVertical,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildFoodImage(),
            Text(
              foodItem['name']!,
              style: TextStyle(
                fontSize: kFoodNameFontSize,
                fontWeight: kFoodNameFontWeight,
                color: isClickable ? Colors.black : Colors.grey,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFoodImage() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(kBorderRadius)),
      ),
      height: kImageHeight,
      width: kImageWidth,
      child: Opacity(
        opacity: isClickable ? 1.0 : 0.2,
        child: ColorFiltered(
          colorFilter: isClickable
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: Image.asset(
            foodItem['image']!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.fastfood_outlined,
              size: 80,
            ),
          ),
        ),
      ),
    );
  }
}
