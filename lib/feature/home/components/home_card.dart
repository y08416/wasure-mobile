import 'package:flutter/material.dart';

class HomeCard extends StatelessWidget {
  final String title;
  final String iconPath;
  final Color color;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  const HomeCard({
    Key? key,
    required this.title,
    required this.iconPath,
    required this.color,
    required this.onTap,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        child: Card(
          elevation: 4,
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  iconPath,
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}