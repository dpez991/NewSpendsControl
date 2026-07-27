import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spendscontrol/models/clases.dart';
import 'package:spendscontrol/models/mtd.dart';

class CrearUsuarioScreen extends StatefulWidget {
  const CrearUsuarioScreen({super.key});

  @override
  State<CrearUsuarioScreen> createState() => _CrearUsuarioScreenState();
}

class _CrearUsuarioScreenState extends State<CrearUsuarioScreen> {
  final nombreController = TextEditingController();
  final codigoController = TextEditingController();
  final correoController = TextEditingController();
  final claveController = TextEditingController();
  final confirmarClaveController = TextEditingController();

  final nombreFocus = FocusNode();
  final codigoFocus = FocusNode();
  final correoFocus = FocusNode();
  final claveFocus = FocusNode();
  final confirmarClaveFocus = FocusNode();

  bool guardando = false;
  bool verClave = false;
  bool verConfirmarClave = false;

  List<String> obtenerErroresContrasena(String clave) {
    List<String> errores = [];
    if (clave.length < 12) errores.add("• Mínimo 12 caracteres");
    if (!RegExp(r'[A-Z]').hasMatch(clave)) errores.add("• Al menos una letra mayúscula");
    if (!RegExp(r'[a-z]').hasMatch(clave)) errores.add("• Al menos una letra minúscula");
    if (!RegExp(r'[0-9]').hasMatch(clave)) errores.add("• Al menos un número");
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{};:,.<>?/\\|`~]').hasMatch(clave)) {
      errores.add("• Al menos un carácter especial (!@#\$%^&*...)");
    }
    return errores;
  }

  String? validarFormatoCorreo(String correo) {
    final regexCorreo = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!regexCorreo.hasMatch(correo)) {
      return "Ingrese un correo electrónico válido (ej: usuario@correo.com)";
    }
    return null;
  }

  @override
  void dispose() {
    nombreController.dispose();
    codigoController.dispose();
    correoController.dispose();
    claveController.dispose();
    confirmarClaveController.dispose();
    nombreFocus.dispose();
    codigoFocus.dispose();
    correoFocus.dispose();
    claveFocus.dispose();
    confirmarClaveFocus.dispose();
    super.dispose();
  }

  Future<void> guardarUsuario() async {
    final nombre = nombreController.text.trim();
    final codigo = codigoController.text.trim();
    // toLowerCase() para garantizar consistencia con Firebase Auth (que normaliza correos a minúsculas)
    final correo = correoController.text.trim().toLowerCase();
    final clave = claveController.text;
    final confirmarClave = confirmarClaveController.text;

    if (nombre.isEmpty || codigo.isEmpty || correo.isEmpty || clave.isEmpty || confirmarClave.isEmpty) {
      await mtdMessage(context, "Por favor complete todos los campos", 2);
      return;
    }

    final errorCorreo = validarFormatoCorreo(correo);
    if (errorCorreo != null) {
      await mtdMessage(context, errorCorreo, 2);
      return;
    }

    final erroresClave = obtenerErroresContrasena(clave);
    if (erroresClave.isNotEmpty) {
      await mtdMessage(context, "La contraseña no cumple los requisitos:\n${erroresClave.join('\n')}", 2);
      return;
    }

    if (clave != confirmarClave) {
      await mtdMessage(context, "La contraseña y la confirmación no coinciden", 2);
      return;
    }

    setState(() => guardando = true);

    try {
      // --- FIREBASE AUTH: Crear usuario con correo y contraseña ---
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correo,
        password: clave,
      );

      final uid = credential.user!.uid;

      // --- FIRESTORE: Guardar perfil del usuario ---
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nombre': nombre,
        'codigo': codigo,
        'correo': correo,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'estado': 1,
      });

      if (!mounted) return;
      await mtdMessage(context, "Usuario creado correctamente", 3);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String mensaje = 'No se pudo crear el usuario';
      if (e.code == 'email-already-in-use') {
        mensaje = 'Ya existe una cuenta con ese correo electrónico';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El formato del correo electrónico no es válido';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña es demasiado débil';
      }
      await mtdMessage(context, mensaje, 4);
    } catch (_) {
      if (!mounted) return;
      await mtdMessage(context, "No se pudo crear el usuario", 4);
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Widget _campoContrasena(
    String label,
    TextEditingController controller,
    FocusNode focusNode,
    bool verTexto,
    VoidCallback onToggleVer,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        clsMainLabelField(label),
        const SizedBox(height: 6),
        TextField(
          focusNode: focusNode,
          controller: controller,
          obscureText: !verTexto,
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            labelText: "Ingrese la contraseña",
            labelStyle: GoogleFonts.dmSans(color: mtd_get_color_0()),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: mtd_get_color_2(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(
                verTexto ? Icons.visibility_off : Icons.visibility,
                color: mtd_get_color_0(),
              ),
              onPressed: onToggleVer,
            ),
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      appBar: AppBar(
        toolbarHeight: 100,
        title: Text(
          "CREAR USUARIO",
          style: GoogleFonts.poppins(
            fontSize: 36,
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
                  clsTextField("NOMBRE", nombreController, "Ingrese el nombre", false, 25.0, TextInputType.text, nombreFocus, null),
                  clsTextField("CODIGO DE USUARIO", codigoController, "Ingrese el codigo", false, 25.0, TextInputType.text, codigoFocus, null),
                  _campoCorreo(),
                  _campoContrasena(
                    "CONTRASEÑA",
                    claveController,
                    claveFocus,
                    verClave,
                    () => setState(() => verClave = !verClave),
                  ),
                  _campoContrasena(
                    "CONFIRMAR CONTRASEÑA",
                    confirmarClaveController,
                    confirmarClaveFocus,
                    verConfirmarClave,
                    () => setState(() => verConfirmarClave = !verConfirmarClave),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: guardando
                        ? CircularProgressIndicator(color: mtd_get_color_2())
                        : clsButton(context, guardarUsuario, "Guardar"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}