import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Imports de tus pantallas (Verificados y unificados)
import 'package:spendscontrol/screens/splashscreen.dart';
import 'package:spendscontrol/screens/BarraMenu.dart';
import 'package:spendscontrol/screens/crear_usuario.dart';
import 'package:spendscontrol/screens/recuperar_clave.dart';

// Imports de tus modelos y utilidades compartidas
import 'package:spendscontrol/base/database.dart';
import 'package:spendscontrol/models/mtd.dart';
import 'package:spendscontrol/models/clases.dart';

void main() {
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
  final TextEditingController cuentaController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();
  bool vrCargandoUsuarios = true;
  bool vrHayUsuariosHoy = false;

  // Nodos de enfoque para gestionar el teclado limpiamente
  final cuentaFocus = FocusNode();
  final contrasenaFocus = FocusNode();
  bool verClave = false;

  @override
  void initState() {
    super.initState();
    validarUsuariosLocales();
  }

  Future<void> validarUsuariosLocales() async {
    final hayUsuarios = await DatabaseHelper().mtdDBLocalBuscarSiHayUsuariosHoy();

    if (!mounted) return;

    setState(() {
      vrHayUsuariosHoy = hayUsuarios;
      vrCargandoUsuarios = false;
    });
  }

  void crearUsuario() {
    abrirCrearUsuario();
  }

  Future<void> recuperarClave() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const RecuperarClaveScreen(),
      ),
    );
  }

  Future<void> abrirCrearUsuario() async {
    final usuarioCreado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CrearUsuarioScreen(),
      ),
    );

    if (!mounted) return;

    if (usuarioCreado == true) {
      setState(() {
        vrCargandoUsuarios = true;
      });

      await validarUsuariosLocales();
    }
  }

  void validarInicioSesion() async {
    final cuenta = cuentaController.text.trim();
    final contrasena = contrasenaController.text.trim();

    if (cuenta.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos')),
      );
      return;
    }

    var vrObjeto = await mtdLoginRecord(cuenta, contrasena);

    if (!mounted) return;

    int vrId = vrObjeto?["id"];
    String vrNombre = vrObjeto?["nombre"];

    if (vrNombre.isNotEmpty) {
      if (vrId == -1) {
        mtdMessage(context, "Actualmente no existe un usuario creado, por favor proceda a crear un usuario", 2);
      }
      else {
        var usuario = Usuario(
          id: vrId,
          nombre: vrNombre,
        );

        Provider.of<SesionProvider>(context, listen: false).setUsuario(usuario);

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const Barramenu()),
        // );

        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (_) => Barramenu()),
        //   (route) => false,
        // );

        
        // Feedback visual rápido antes de saltar de pantalla
        // mtdMessage(context, "Iniciando...", 1);

        // Ejecuta el salto al contenedor principal de navegación
        mtdPantalla1();
      }
    } else {
      await mtdMessage(context, "Usuario y clave incorrectos, por favor intente otra vez", 2);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Cuenta o contraseña incorrecta')),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    if (vrCargandoUsuarios) ...[
                      Center(
                        child: CircularProgressIndicator(
                          color: mtd_get_color_2(),
                        ),
                      ),
                    ] else if (vrHayUsuariosHoy) ...[
                      clsTextField("CÓDIGO DE USUARIO", cuentaController, "Ingrese su usuario", false, 25.0, TextInputType.text, cuentaFocus, null),
                      // clsTextField("CONTRASEÑA", contrasenaController, "Ingrese su contraseña", true, 25.0, TextInputType.text, contrasenaFocus, null),
                      clsCampoContrasena(
                        "CONTRASEÑA",
                        "Ingrese la nueva contraseña",
                        contrasenaController,
                        contrasenaFocus,
                        verClave,
                        () => setState(() => verClave = !verClave),
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: vrCargandoUsuarios
                              ? [
                                  CircularProgressIndicator(
                                    color: mtd_get_color_2(),
                                  ),
                                ]
                              : vrHayUsuariosHoy
                                  ? [
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
                                      clsButton(context, mtd_close_app, "Salir"),
                                    ]
                                  : [
                                      clsButton(context, crearUsuario, "Crear usuario"),
                                    ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 100),
                      clsButton(context, crearUsuario, "Crear usuario"),
                    ],
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // CORREGIDO: Ahora abre la BarraMenu para poder recorrer todo el proyecto
  Future<void> mtdPantalla1 () async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const Barramenu(),
      ),
    );
  }
}

