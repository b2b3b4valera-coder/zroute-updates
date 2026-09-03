import 'package:flutter/material.dart';



class PatternPainter extends CustomPainter {

  final Color color;

  PatternPainter(this.color);



  @override

  void paint(Canvas canvas, Size size) {

    final paint = Paint()

      ..color = color

      ..style = PaintingStyle.stroke

      ..strokeWidth = 1.0;



    for (double i = -size.height; i < size.width; i += 30) {

      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);

      canvas.drawLine(Offset(i + size.height, 0), Offset(i, size.height), paint);

    }

  }



  @override

  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}



class BloodDripPainter extends CustomPainter {

  final Color color;

  BloodDripPainter(this.color);



  @override

  void paint(Canvas canvas, Size size) {

    final paint = Paint()

      ..color = color

      ..style = PaintingStyle.fill;



    final path = Path();



    void drawDrip(double x, double width, double height) {

      path.moveTo(x, size.height);

      path.cubicTo(x, size.height + height * 0.6,

          x + width * 0.3, size.height + height,

          x + width * 0.5, size.height + height);

      path.cubicTo(x + width * 0.7, size.height + height,

          x + width, size.height + height * 0.6,

          x + width, size.height);

    }



    drawDrip(size.width * 0.15, 12, 14);

    drawDrip(size.width * 0.4, 8, 20);

    drawDrip(size.width * 0.7, 14, 10);

    drawDrip(size.width * 0.85, 8, 16);



    canvas.drawPath(path, paint);

  }



  @override

  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

}



