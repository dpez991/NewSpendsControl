import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spendscontrol/models/clases.dart';
import 'package:spendscontrol/models/mtd.dart';

class RecuperarClaveScreen extends StatefulWidget {
  const RecuperarClaveScreen({super.key});

  @override
  State<RecuperarClaveScreen> createState() => _RecuperarClaveScreenState();
}

class _RecuperarClaveScreenState extends State<RecuperarClaveScreen> {
  final correoController = TextEditingController();
  final correoFocus = FocusNode();

  bool enviando = false;

  @override
  void dispose() {
    correoController.dispose();
    correoFocus.dispose();
    super.dispose();
  }

  String? _validarFormatoCorreo(String correo) {
    final regexCorreo = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!regexCorreo.hasMatch(correo)) {
      return "Ingrese un correo electrónico válido (ej: usuario@correo.com)";
    }
    return null;
  }

  // Consulta Firestore para verificar si el correo existe antes de enviar el enlace.
  // El correo debe llegar ya normalizado (trim + toLowerCase).
  // Retorna null si ocurre un error de red/Firestore, para manejarlo por separado.
  Future<bool?> _correoExisteEnFirestore(String correo) async {
    try {
      final resultado = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('correo', isEqualTo: correo)
          .limit(1)
          .get();
      return resultado.docs.isNotEmpty;
    } catch (_) {
      return null; // error de red o Firestore — se maneja en el llamador
    }
  }

  Future<void> enviarCorreoRecuperacion() async {
    FocusScope.of(context).unfocus();
    // trim() + toLowerCase() para garantizar consistencia con Firestore y Firebase Auth
    final correo = correoController.text.trim().toLowerCase();

    if (correo.isEmpty) {
      await mtdMessage(context, "Ingrese el correo electrónico", 2);
      return;
    }

    final errorFormato = _validarFormatoCorreo(correo);
    if (errorFormato != null) {
      await mtdMessage(context, errorFormato, 2);
      return;
    }

    setState(() => enviando = true);

    try {
      // --- VALIDACIÓN FIRESTORE: Verificar existencia del correo antes de enviar ---
      final existe = await _correoExisteEnFirestore(correo);
      if (!mounted) return;

      if (existe == null) {
        // Error de red o Firestore al consultar
        await mtdMessage(context, 'No se pudo verificar el correo. Verifique su conexión e intente de nuevo.', 4);
        return;
      }

      if (!existe) {
        await mtdMessage(context, 'El correo no se encuentra registrado.', 2);
        return;
      }

      // --- FIREBASE AUTH: Enviar correo de restablecimiento de contraseña ---
      await FirebaseAuth.instance.sendPasswordResetEmail(email: correo);
      if (!mounted) return;
      await mtdMessage(
        context,
        "Se ha enviado un enlace a tu correo para restablecer la contraseña. Revisa también tu carpeta de spam.",
        3,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String mensaje = 'No se pudo enviar el correo de recuperación';
      if (e.code == 'user-not-found') {
        mensaje = 'El correo no se encuentra registrado.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El formato del correo electrónico no es válido';
      } else if (e.code == 'too-many-requests') {
        mensaje = 'Demasiadas solicitudes. Intente más tarde';
      }
      await mtdMessage(context, mensaje, 2);
    } catch (_) {
      if (!mounted) return;
      await mtdMessage(context, 'No se pudo enviar el correo de recuperación', 4);
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  Widget _campoCorreo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        clsMainLabelField("CORREO ELECTRONICO"),
        const SizedBox(height: 6),
        TextField(
          focusNode: correoFocus,
          controller: correoController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => enviarCorreoRecuperacion(),
          decoration: InputDecoration(
            labelText: "Ingrese el correo electronico",
            labelStyle: GoogleFonts.dmSans(color: mtd_get_color_0()),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: mtd_get_color_2(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFEF7FF),
      appBar: AppBar(
        toolbarHeight: 100,
        title: Text(
          "RECUPERAR CLAVE",
          style: GoogleFonts.poppins(
            fontSize: 32,
            color: mtd_get_color_2(),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFEF7FF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _campoCorreo(),
                  const SizedBox(height: 15),
                  Center(
                    child: enviando
                        ? CircularProgressIndicator(color: mtd_get_color_2())
                        : clsButton(context, enviarCorreoRecuperacion, "Enviar enlace"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}