import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mtd.dart';

class Pantalla1 extends StatefulWidget {
  const Pantalla1({super.key});

  @override
  _Pantalla1 createState() => _Pantalla1();
}

class _Pantalla1 extends State<Pantalla1> {
  final TextEditingController _latController = TextEditingController(text: "0.00");
  final TextEditingController _lngController = TextEditingController(text: "0.00");

  final bool _isLoading = false;

  List<Map<String, dynamic>> lstMpDepartamentos = [];
  List<Map<String, dynamic>> lstMpMunicipios = [];
  // Map<int, String> _mapaTipos = {};
  Map<int, String> mpDepartamentos = {};
  Map<int, String> mpMunicipios = {};

  final TextEditingController cantpagarController = TextEditingController();
  String? _seleccion;
  String? vrDepartamentoSeleccionado;
  String? vrMunicipioSeleccionado;
  int vrIdDepartamentoSeleccionado = 0;
  int vrIdMunicipioSeleccionado = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    cantpagarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: mtd_get_color_2(), // same color as your header
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Pantalla de pruebas',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      elevation: 0,
    ),


      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20), // adds padding inside
            child: Column(
              
              children: [
                const SizedBox(height: 20),
                Text(
                  'Subtítulo',
                  style: GoogleFonts.poppins(
                    fontSize: 45,
                    color: mtd_get_color_3(),
                  ),
                ),
                //NOMBRE COMPLETO
                
              ],
        ),
      ),
    ],
  ),
    );
  }
}