import 'dart:math';
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
  // PARTE 1: codigoController y codigoFocus eliminados completamente.
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final claveController = TextEditingController();
  final confirmarClaveController = TextEditingController();

  final nombreFocus = FocusNode();
  final correoFocus = FocusNode();
  final claveFocus = FocusNode();
  final confirmarClaveFocus = FocusNode();

  bool guardando = false;
  bool verClave = false;
  bool verConfirmarClave = false;

  // ---------------------------------------------------------------------------
  // PARTE 2: Generación automática del código de usuario.
  // Formato: USR-XXXXXXXX (8 caracteres hexadecimales en mayúsculas).
  // Combina microsegundos del sistema + valor aleatorio para evitar colisiones.
  // ---------------------------------------------------------------------------
  String _generarCodigoUnico() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rnd = Random().nextInt(0xFFFF);
    // XOR de los últimos 28 bits del timestamp con 16 bits aleatorios
    final combinado = (ts ^ (rnd << 12)) & 0xFFFFFFFF;
    return 'USR-${combinado.toRadixString(16).toUpperCase().padLeft(8, '0')}';
  }

  // ---------------------------------------------------------------------------
  // PARTE 5: Validación completa del nombre.
  // Acepta: letras (a-z, A-Z), vocales con acento, Ñ/ñ, espacios simples.
  // Rechaza: dígitos, símbolos, espacios dobles/triples, inicio/fin con espacio,
  //          vacío, más de 60 caracteres.
  // ---------------------------------------------------------------------------
  String? _validarNombre(String nombre) {
    if (nombre.isEmpty) {
      return 'El nombre es obligatorio.';
    }
    if (nombre.length > 60) {
      return 'El nombre es demasiado largo (máximo 60 caracteres).';
    }
    if (nombre.startsWith(' ')) {
      return 'El nombre no puede iniciar con espacios.';
    }
    if (nombre.endsWith(' ')) {
      return 'El nombre no puede terminar con espacios.';
    }
    if (nombre.contains('  ')) {
      return 'No se permiten espacios consecutivos.';
    }
    // Solo permite letras (incluyendo acentuadas y Ñ) y espacios simples.
    final regexNombre = RegExp(
      r'^[a-zA-ZáéíóúÁÉÍÓÚüÜàèìòùÀÈÌÒÙäëïöÄËÏÖñÑ ]+$',
    );
    if (!regexNombre.hasMatch(nombre)) {
      return 'Solo se permiten letras y espacios simples. No se permiten números ni caracteres especiales.';
    }
    return null; // válido
  }

  // ---------------------------------------------------------------------------
  // PARTE 6: Validación de formato de correo (existente, sin cambios).
  // ---------------------------------------------------------------------------
  String? validarFormatoCorreo(String correo) {
    final regexCorreo = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!regexCorreo.hasMatch(correo)) {
      return 'Ingrese un correo electrónico válido (ej: usuario@correo.com)';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // PARTE 6: Verificación previa de correo duplicado en Firestore.
  // Se consulta antes de intentar crear el usuario en Firebase Auth para dar
  // un mensaje más claro. El catch de FirebaseAuthException actúa como respaldo.
  // ---------------------------------------------------------------------------
  Future<bool> _correoYaRegistrado(String correo) async {
    try {
      final resultado = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('correo', isEqualTo: correo)
          .limit(1)
          .get();
      return resultado.docs.isNotEmpty;
    } catch (_) {
      // Si la consulta falla, se continúa y Firebase Auth actúa como árbitro final.
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Validaciones de contraseña (existentes, sin cambios).
  // ---------------------------------------------------------------------------
  List<String> obtenerErroresContrasena(String clave) {
    List<String> errores = [];
    if (clave.length < 12) errores.add('• Mínimo 12 caracteres');
    if (!RegExp(r'[A-Z]').hasMatch(clave)) {
      errores.add('• Al menos una letra mayúscula');
    }
    if (!RegExp(r'[a-z]').hasMatch(clave)) {
      errores.add('• Al menos una letra minúscula');
    }
    if (!RegExp(r'[0-9]').hasMatch(clave)) {
      errores.add('• Al menos un número');
    }
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{};:,.<>?/\\|`~]').hasMatch(clave)) {
      errores.add('• Al menos un carácter especial (!@#\$%^&*...)');
    }
    return errores;
  }

  @override
  void dispose() {
    // PARTE 1: codigoController.dispose() y codigoFocus.dispose() eliminados.
    nombreController.dispose();
    correoController.dispose();
    claveController.dispose();
    confirmarClaveController.dispose();
    nombreFocus.dispose();
    correoFocus.dispose();
    claveFocus.dispose();
    confirmarClaveFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // PARTE 4: Flujo de registro simplificado — solo 4 campos del usuario.
  // PARTE 2: El código se genera automáticamente aquí.
  // PARTE 6: Verificación previa de correo duplicado.
  // ---------------------------------------------------------------------------
  Future<void> guardarUsuario() async {
    FocusScope.of(context).unfocus();
    // AUDITORÍA: Se lee el texto RAW antes del trim() para que las validaciones
    // de espacio inicial/final en _validarNombre() funcionen correctamente.
    // El nombre trimmeado se usa únicamente para guardar en Firestore.
    final nombreRaw = nombreController.text;
    final nombreGuardar = nombreRaw.trim();
    // toLowerCase() para garantizar consistencia con Firebase Auth y Firestore.
    final correo = correoController.text.trim().toLowerCase();
    final clave = claveController.text;
    final confirmarClave = confirmarClaveController.text;

    // PARTE 4: Validación de campos vacíos — verifica el texto trimmeado.
    if (nombreGuardar.isEmpty || correo.isEmpty || clave.isEmpty || confirmarClave.isEmpty) {
      await mtdMessage(context, 'Por favor complete todos los campos', 2);
      return;
    }

    // PARTE 5: Validación completa del nombre sobre el texto RAW.
    // Esto permite detectar espacios al inicio/final antes del trim.
    final errorNombre = _validarNombre(nombreRaw);
    if (errorNombre != null) {
      await mtdMessage(context, errorNombre, 2);
      return;
    }

    // PARTE 6: Validación de formato del correo.
    final errorCorreo = validarFormatoCorreo(correo);
    if (errorCorreo != null) {
      await mtdMessage(context, errorCorreo, 2);
      return;
    }

    // Validación de contraseña.
    final erroresClave = obtenerErroresContrasena(clave);
    if (erroresClave.isNotEmpty) {
      await mtdMessage(
        context,
        'La contraseña no cumple los requisitos:\n${erroresClave.join('\n')}',
        2,
      );
      return;
    }

    if (clave != confirmarClave) {
      await mtdMessage(
        context,
        'La contraseña y la confirmación no coinciden',
        2,
      );
      return;
    }

    setState(() => guardando = true);

    try {
      // PARTE 6: Verificación previa de correo duplicado en Firestore.
      final duplicado = await _correoYaRegistrado(correo);
      if (!mounted) return;
      if (duplicado) {
        await mtdMessage(context, 'Este correo ya está registrado.', 2);
        // AUDITORÍA: guard mounted después del await del dialog.
        if (!mounted) return;
        return;
      }

      // PARTE 2: Generar código único ANTES de crear el usuario en Auth.
      // Así está disponible desde el inicio del flujo de persistencia.
      final codigoGenerado = _generarCodigoUnico();

      // --- FIREBASE AUTH: Crear usuario con correo y contraseña ---
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: correo, password: clave);

      final uid = credential.user!.uid;

      // --- FIRESTORE: Guardar perfil del usuario (campo 'codigo' se mantiene) ---
      // Se guarda 'nombreGuardar' (trimmeado) y 'correo' (normalizado).
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nombre': nombreGuardar,
        'codigo': codigoGenerado, // Generado automáticamente, nunca escrito por el usuario
        'correo': correo,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'estado': 1,
      });

      if (!mounted) return;
      await mtdMessage(context, 'Usuario creado correctamente', 3);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String mensaje = 'No se pudo crear el usuario';
      if (e.code == 'email-already-in-use') {
        // Respaldo: Firebase Auth detecta duplicado si la consulta Firestore falló.
        mensaje = 'Este correo ya está registrado.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El formato del correo electrónico no es válido';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña es demasiado débil';
      }
      await mtdMessage(context, mensaje, 4);
    } catch (_) {
      if (!mounted) return;
      await mtdMessage(context, 'No se pudo crear el usuario', 4);
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  // ---------------------------------------------------------------------------
  // PARTE 5 + PARTE 8: Campo NOMBRE personalizado SIN UpperCaseTextFormatter.
  // clsTextField aplica UpperCaseTextFormatter globalmente, lo que bloquearía
  // minúsculas, acentos y ñ. Este widget local resuelve eso visualmente igual.
  // ---------------------------------------------------------------------------
  Widget _campoNombre() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        clsMainLabelField('NOMBRE'),
        const SizedBox(height: 6),
        TextField(
          focusNode: nombreFocus,
          controller: nombreController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(correoFocus),
          // Sin UpperCaseTextFormatter — permite minúsculas, acentos y ñ.
          decoration: InputDecoration(
            labelText: 'Ingrese el nombre',
            labelStyle: GoogleFonts.dmSans(color: mtd_get_color_0()),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: mtd_get_color_2(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Campo CORREO (existente, sin cambios).
  // ---------------------------------------------------------------------------
  Widget _campoCorreo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        clsMainLabelField('CORREO ELECTRONICO'),
        const SizedBox(height: 6),
        TextField(
          focusNode: correoFocus,
          controller: correoController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(claveFocus),
          decoration: InputDecoration(
            labelText: 'Ingrese el correo electronico',
            labelStyle: GoogleFonts.dmSans(color: mtd_get_color_0()),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: mtd_get_color_2(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          'CREAR USUARIO',
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
                  // PARTE 5 + PARTE 8: Campo nombre sin UpperCaseTextFormatter.
                  _campoNombre(),
                  // PARTE 1: Campo "CODIGO DE USUARIO" eliminado completamente.
                  _campoCorreo(),
                  // PARTE 8: Se usa el widget compartido clsCampoContrasena de clases.dart.
                  clsCampoContrasena(
                    'CONTRASEÑA',
                    'Ingrese la contraseña',
                    claveController,
                    claveFocus,
                    verClave,
                    () => setState(() => verClave = !verClave),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(confirmarClaveFocus),
                  ),
                  clsCampoContrasena(
                    'CONFIRMAR CONTRASEÑA',
                    'Confirme la contraseña',
                    confirmarClaveController,
                    confirmarClaveFocus,
                    verConfirmarClave,
                    () => setState(() => verConfirmarClave = !verConfirmarClave),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => guardarUsuario(),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: guardando
                        ? CircularProgressIndicator(color: mtd_get_color_2())
                        : clsButton(context, guardarUsuario, 'Guardar'),
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