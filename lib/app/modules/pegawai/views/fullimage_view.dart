import 'package:flutter/material.dart';

import 'package:get/get.dart';

class FullimageView extends GetView {
  final String imageUrl;
  FullimageView({super.key, required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
