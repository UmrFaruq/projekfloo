import 'package:flutter/material.dart';
import '../theme/colors.dart';

class CategoryChip extends StatelessWidget {

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,

      child: Container(
        margin: const EdgeInsets.only(right: 10),

        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),

        decoration: BoxDecoration(
          color: isSelected
              ? PastelColors.sage
              : Colors.white,

          borderRadius: BorderRadius.circular(20),
        ),

        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : PastelColors.grey,
          ),
        ),
      ),
    );
  }
}