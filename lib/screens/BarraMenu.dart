// import 'package:MassApp/screen/clientesListado.dart';
// import 'package:MassApp/screen/OrdenesListado.dart';
// import 'package:MassApp/screen/perfil.dart';
// import 'package:MassApp/screen/facturasComprasListado.dart';
// import 'package:MassApp/screen/ajustesListado.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../models/mtd.dart';
import '../models/clases.dart';
import 'movimientos.dart';
import 'principal.dart';
import 'categorias.dart';
import 'presupuesto_screen.dart';

class Barramenu extends StatefulWidget {
  const Barramenu({super.key});

  @override
  State<Barramenu> createState() => _BarraMenuState();
}

class _BarraMenuState extends State<Barramenu> {
  int _paginaActual = 0;
  // int vrIdPerfil = Sesion.usuarioActual!.idPerfil;

 final List<Widget> _paginas = [
  PantallaPrincipal(),
  const Movimientos(),
  const AdministracionCategorias(),
  const PresupuestoScreen(),
];

  @override
  void initState() {
    super.initState();
    // startAutoSyncLocal();
    // _syncService = SyncService();

    // final sesion = context.read<SesionProvider>();
    // _syncService.startAutoSync(sesion);
  }

  // void startAutoSyncLocal()
  // {
  //   final sesion = context.read<SesionProvider>();
  //   // final vrIdUsuario = sesion.usuario!.idCuenta;

  //   startAutoSync(sesion);
  // }

  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final bool salir = await mtdConfirmarDatos(context, '¿Está seguro que desea salir?');

    if (salir) {
      // --- FIREBASE AUTH: Cerrar sesión ---
      await FirebaseAuth.instance.signOut();

      // Limpiar el estado de sesión del Provider
      if (context.mounted) {
        Provider.of<SesionProvider>(context, listen: false).clearUsuario();
      }

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const IniciarSesion()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> vrOpciones;
    // final sesion = Provider.of<SesionProvider>(context);
    // final vrIdPerfil = sesion.usuario?.idPerfil ?? 0;

    // if(vrIdPerfil == 2)
    // {
      // _paginaActual = 1;
     vrOpciones = [
  Icon(Icons.home, size: 30, color: Colors.white),
  Icon(Icons.list_alt, size: 30, color: Colors.white),
  Icon(Icons.category, size: 30, color: Colors.white),
  Icon(Icons.attach_money, size: 30, color: Colors.white),
  Icon(Icons.logout, size: 30, color: Colors.white),
];
    // }
    // else
    // {
    //   // _paginaActual = 2;
    //   vrOpciones = [
    //     Icon(Icons.person_add_rounded, size: 30, color: Colors.white),
    //     Icon(Icons.view_list, size: 30, color: Colors.white),
    //     Icon(Icons.person, size: 30, color: Colors.white),
    //     // Icon(Icons.production_quantity_limits_sharp, size: 30, color: Colors.white),
    //     Icon(Icons.logout, size: 30, color: Colors.white),
    //   ];
    // }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Container(
            color: mtd_get_color_0(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(vrOpciones.length, (index) {
                return IconButton(
                  icon: vrOpciones[index],
                  onPressed: () {
                    if (index == vrOpciones.length - 1) {
                      _confirmarCerrarSesion(context);
                    } else {
                      setState(() {
                        _paginaActual = index;
                      });
                    }
                  },
                );
              }),
            ),
          ),
        ),
      ),
      body: _paginas[_paginaActual],
      // body: (vrIdPerfil == 2
      //     ? _paginasAdmin[_paginaActual]
      //     : _paginas[_paginaActual]),
    );

  }
}
