import 'package:flutter/material.dart';
import '../main.dart';
import '../models/mtd.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
//28
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const IniciarSesion()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mtd_get_color_2(),
      body: Center(
        child: Image.asset(
          'assets/images/logo_initial.png',
          width: 500,
          height: 500,//2003
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}