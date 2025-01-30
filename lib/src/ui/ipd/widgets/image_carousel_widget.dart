import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class ImageCarousel extends StatelessWidget {
  double widthRatio;
  double heightRatio;

  ImageCarousel({required this.widthRatio, required this.heightRatio});

  final List<String> imagePaths = [
    'assets/images/png/slide_images/slide_01.png',
    'assets/images/png/slide_images/slide_02.png',
    'assets/images/png/slide_images/slide_03.png',
    'assets/images/png/slide_images/slide_04.png',
    'assets/images/png/slide_images/slide_05.png',
    'assets/images/png/slide_images/slide_06.png',
    'assets/images/png/slide_images/slide_07.png',
    'assets/images/png/slide_images/slide_08.png',
    'assets/images/png/slide_images/slide_09.png',
    'assets/images/png/slide_images/slide_10.png',
    'assets/images/png/slide_images/slide_11.png',
  ];

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        height: 302 * heightRatio,
        viewportFraction: 1.0,
        autoPlayInterval: Duration(seconds: 12),
      ),
      items: imagePaths.map((imagePath) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: 1080 * widthRatio,
              color: Colors.white,
              child: Image.asset(
                imagePath,
                fit: BoxFit.fill,
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
