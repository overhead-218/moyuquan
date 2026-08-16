import 'package:flutter/material.dart';
import '../services/spot_avatar_generator.dart';
import '../services/spot_service.dart';

/// 钓点头像展示示例�?class SpotAvatarDemoPage extends StatelessWidget {
  const SpotAvatarDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spots = SpotService.all.take(30).toList();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A7C5C),
        foregroundColor: Colors.white,
        title: const Text('钓点数字头像'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: spots.length,
        itemBuilder: (context, index) {
          final spot = spots[index];
          return Column(
            children: [
              // 头像
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SpotAvatarGenerator.generate(
                  spotId: spot.id,
                  spotType: spot.type,
                  fishSpecies: spot.fishSpecies,
                  size: 80,
                ),
              ),
              const SizedBox(height: 8),
              // 名称
              Text(
                spot.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
              // 类型标签
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A7C5C).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  spot.typeEmoji,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
