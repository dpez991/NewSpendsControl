import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Imports de tus pantallas (Verificados y unificados)
import 'package:spendscontrol/screens/splashscreen.dart';
import 'package:spendscontrol/screens/BarraMenu.dart';
import 'package:spendscontrol/screens/crear_usuario.dart';
import 'package:spendscontrol/screens/recuperar_clave.dart';

// Imports de tus modelos y utilidades compartidas
import 'package:spendscontrol/models/mtd.dart';
import 'package:spendscontrol/models/clases.dart';
import 'package:spendscontrol/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SesionProvider(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SpendsControl',
        home: SplashScreen(), // <-- El flujo inicia correctamente aquí
      ),
    );
  }
}

class IniciarSesion extends StatefulWidget {
  const IniciarSesion({super.key}); 
  
  @override
  State<IniciarSesion> createState() => _IniciarSesionState();
}

class _IniciarSesionState extends State<IniciarSesion> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();

  // Nodos de enfoque para gestionar el teclado limpiamente
  final correoFocus = FocusNode();
  final contrasenaFocus = FocusNode();
  bool verClave = false;
  bool _cargando = false;

  @override
  void dispose() {
    correoController.dispose();
    contrasenaController.dispose();
    correoFocus.dispose();
    contrasenaFocus.dispose();
    super.dispose();
  }

  void crearUsuario() {
    abrirCrearUsuario();
  }

  Future<void> recuperarClave() async {
    FocusScope.of(context).unfocus();
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const RecuperarClaveScreen(),
      ),
    );
  }

  Future<void> abrirCrearUsuario() async {
    FocusScope.of(context).unfocus();
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CrearUsuarioScreen(),
      ),
    );
  }

  Future<void> validarInicioSesion() async {
    FocusScope.of(context).unfocus();
    // trim().toLowerCase() para normalizar el correo antes de enviarlo a Firebase Auth
    final correo = correoController.text.trim().toLowerCase();
    final contrasena = contrasenaController.text.trim();

    if (correo.isEmpty || contrasena.isEmpty) {
      await mtdMessage(context, 'Por favor complete todos los campos', 2);
      return;
    }

    setState(() => _cargando = true);

    try {
      // --- FIREBASE AUTH ---
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correo,
        password: contrasena,
      );

      if (!mounted) return;

      final uid = credential.user!.uid;

      // Obtener datos del perfil desde Firestore
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        await mtdMessage(context, 'No se encontró el perfil del usuario', 4);
        return;
      }

      final data = doc.data()!;
      final usuario = Usuario(
        uid: uid,
        nombre: data['nombre'] ?? '',
        codigo: data['codigo'] ?? '',
        correo: data['correo'] ?? correo,
      );

      Provider.of<SesionProvider>(context, listen: false).setUsuario(usuario);

      // Ejecuta el salto al contenedor principal de navegación
      await mtdPantalla1();

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String mensaje = 'Correo o contraseña incorrectos, por favor intente otra vez';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        mensaje = 'Correo o contraseña incorrectos, por favor intente otra vez';
      } else if (e.code == 'user-disabled') {
        mensaje = 'Esta cuenta ha sido deshabilitada';
      } else if (e.code == 'too-many-requests') {
        mensaje = 'Demasiados intentos fallidos. Intente más tarde';
      }
      await mtdMessage(context, mensaje, 2);
    } catch (_) {
      if (!mounted) return;
      await mtdMessage(context, 'Ocurrió un error al iniciar sesión', 4);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Campo correo local sin UpperCaseTextFormatter.
  // clsTextField aplica UpperCaseTextFormatter globalmente (convierte a mayúsculas).
  // Este widget es visualmente idéntico pero permite al usuario escribir
  // en cualquier combinación de mayúsculas/minúsculas sin conversión automática.
  // Internamente, validarInicioSesion() aplica trim().toLowerCase() antes de
  // enviarlo a Firebase Auth, por lo que el comportamiento de autenticación
  // es exactamente el mismo.
  Widget _campoCorreoLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        clsMainLabelField("CORREO ELECTRÓNICO"),
        const SizedBox(height: 6),
        TextField(
          focusNode: correoFocus,
          controller: correoController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(contrasenaFocus),
          // Sin UpperCaseTextFormatter — el usuario ve el texto tal como lo escribe
          decoration: InputDecoration(
            labelText: "Ingrese su correo",
            labelStyle: GoogleFonts.dmSans(color: mtd_get_color_0()),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: mtd_get_color_2(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 25.0),
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
        toolbarHeight: 120,
        title: Text(
          "INICIAR SESIÓN", 
          style: GoogleFonts.poppins(
            fontSize: 45,
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
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,   
                height: MediaQuery.of(context).size.height * 0.3, 
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF7FF), 
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo_initial.png'),
                    fit: BoxFit.contain, 
                  ),
                ),
              ), 
            ), 
            const SizedBox(height: 10),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _campoCorreoLogin(),
                    clsCampoContrasena(
                      "CONTRASEÑA",
                      "Ingrese su contraseña",
                      contrasenaController,
                      contrasenaFocus,
                      verClave,
                      () => setState(() => verClave = !verClave),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => validarInicioSesion(),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _cargando
                            ? [
                                CircularProgressIndicator(
                                  color: mtd_get_color_2(),
                                ),
                              ]
                            : [
                                TextButton(
                                  onPressed: recuperarClave,
                                  child: const Text(
                                    "Recuperar clave",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                clsButton(context, validarInicioSesion, "Iniciar Sesión"),
                                const SizedBox(height: 10),
                                clsButton(context, crearUsuario, "Crear usuario"),
                                const SizedBox(height: 10),
                                clsButton(context, mtd_close_app, "Salir"),
                              ],
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }

  // Abre la BarraMenu para navegar al contenedor principal
  Future<void> mtdPantalla1 () async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const Barramenu(),
      ),
    );
  }
}
