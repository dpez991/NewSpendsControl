import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../models/mtd.dart';
import '../models/clases.dart';
import '../base/firestore_helper.dart';
import 'BarraMenu.dart';

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

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        // Hay sesión activa — cargar perfil de Firestore y entrar directamente
        try {
          final doc = await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(firebaseUser.uid)
              .get();

          if (!mounted) return;

          if (doc.exists) {
            final data = doc.data()!;
            final usuario = Usuario(
              uid: firebaseUser.uid,
              nombre: data['nombre'] ?? '',
              codigo: data['codigo'] ?? '',
              correo: data['correo'] ?? firebaseUser.email ?? '',
            );
            Provider.of<SesionProvider>(context, listen: false).setUsuario(usuario);

            // Crear categorías semilla si es la primera vez que el usuario accede
            await FirestoreHelper().inicializarCategoriasSiEsNecesario();
            if (!mounted) return;

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Barramenu()),
            );
            return;
          }
        } catch (_) {
          // Si falla la carga del perfil, ir al Login normalmente
        }
      }

      // Sin sesión activa → mostrar Login
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