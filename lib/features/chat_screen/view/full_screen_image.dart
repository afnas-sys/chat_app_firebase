import 'package:flutter/material.dart';
import 'package:support_chat/utils/constants/app_colors.dart';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String? tag;

  const FullScreenImage({super.key, required this.imageUrl, this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: Hero(
          tag: tag ?? imageUrl,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.fifthColor,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 50),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
