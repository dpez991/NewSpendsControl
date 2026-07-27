import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendscontrol/base/database.dart';
import 'package:spendscontrol/models/clases.dart';
import 'package:spendscontrol/models/mtd.dart';

class RecuperarClaveScreen extends StatefulWidget {
  const RecuperarClaveScreen({super.key});

  @override
  State<RecuperarClaveScreen> createState() => _RecuperarClaveScreenState();
}

class _RecuperarClaveScreenState extends State<RecuperarClaveScreen> {
  final correoController = TextEditingController();
  final claveController = TextEditingController();
  final confirmarClaveController = TextEditingController();

  final correoFocus = FocusNode();
  final claveFocus = FocusNode();
  final confirmarClaveFocus = FocusNode();

  bool correoValidado = false;
  bool guardando = false;
  bool verClave = false;
  bool verConfirmarClave = false;

  @override
  void dispose() {
    correoController.dispose();
    claveController.dispose();
    confirmarClaveController.dispose();
    correoFocus.dispose();
    claveFocus.dispose();
    confirmarClaveFocus.dispose();
    super.dispose();
  }

  String? _validarFormatoCorreo(String correo) {
    final regexCorreo = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!regexCorreo.hasMatch(correo)) {
      return "Ingrese un correo electrónico válido (ej: usuario@correo.com)";
    }
    return null;
  }

  List<String> _obtenerErroresContrasena(String clave) {
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

  Future<void> validarCorreo() async {
    final correo = correoController.text.trim();

    if (correo.isEmpty) {
      await mtdMessage(context, "Ingrese el correo electronico", 2);
      return;
    }

    final errorFormato = _validarFormatoCorreo(correo);
    if (errorFormato != null) {
      await mtdMessage(context, errorFormato, 2);
      return;
    }

    final existe = await DatabaseHelper().mtdDBLocalExisteCorreoUsuario(correo);
    if (!mounted) return;

    if (!existe) {
      await mtdMessage(context, "El correo no coincide con el usuario registrado", 2);
      return;
    }

    setState(() => correoValidado = true);
  }

  Future<void> guardarClave() async {
    if (!correoValidado) {
      await validarCorreo();
      return;
    }

    final correo = correoController.text.trim();
    final clave = claveController.text;
    final confirmarClave = confirmarClaveController.text;

    if (clave.isEmpty || confirmarClave.isEmpty) {
      await mtdMessage(context, "Ingrese y confirme la nueva contraseña", 2);
      return;
    }

    final erroresClave = _obtenerErroresContrasena(clave);
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
      final filas = await DatabaseHelper().mtdDBLocalActualizarClavePorCorreo(correo, clave);
      if (!mounted) return;

      if (filas > 0) {
        await mtdMessage(context, "Contraseña actualizada correctamente", 3);
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        await mtdMessage(context, "No se pudo actualizar la contraseña", 4);
      }
    } catch (_) {
      if (!mounted) return;
      await mtdMessage(context, "No se pudo actualizar la contraseña", 4);
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Widget _campoContrasena(
    String label,
    String hint,
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
            labelText: hint,
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
                  if (correoValidado) ...[
                    _campoContrasena(
                      "NUEVA CONTRASEÑA",
                      "Ingrese la nueva contraseña",
                      claveController,
                      claveFocus,
                      verClave,
                      () => setState(() => verClave = !verClave),
                    ),
                    _campoContrasena(
                      "CONFIRMAR CONTRASEÑA",
                      "Confirme la nueva contraseña",
                      confirmarClaveController,
                      confirmarClaveFocus,
                      verConfirmarClave,
                      () => setState(() => verConfirmarClave = !verConfirmarClave),
                    ),
                  ],
                  const SizedBox(height: 15),
                  Center(
                    child: guardando
                        ? CircularProgressIndicator(color: mtd_get_color_2())
                        : clsButton(context, guardarClave, correoValidado ? "Guardar" : "Comprobar"),
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