// lib/features/chat/widgets/shimmer_loading_bubble.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoadingBubble extends StatelessWidget {
  final Widget smallAiAvatar; // AI 아바타 위젯 전달받음

  const ShimmerLoadingBubble({Key? key, required this.smallAiAvatar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            smallAiAvatar,
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 10.0, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 80, height: 10.0, color: Colors.white),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
