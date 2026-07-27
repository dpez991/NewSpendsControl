import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../base/database.dart';

Color mtd_get_color_0(){
  return Color.fromARGB(255, 0, 0, 0);
}
Color mtd_get_color_1(){
  return Color(0xFFFEF7FF);
}
Color mtd_get_color_2(){
  return Color.fromARGB(221, 100, 212, 166);
}
Color mtd_get_color_3(){
  return Color.fromARGB(221, 116, 146, 243);
}

String mtd_transform(String input) {
  final Map<String, String> map = {
    'a': '@', 'A': '@',
    'b': '\$', 'B': '\$',
    'c': '.', 'C': '.',
    'd': '¡', 'D': '¡',
    'e': '¿', 'E': '¿',
    'f': "'", 'F': "'",
    'g': '?', 'G': '?',
    'h': '+', 'H': '+',
    'i': '*', 'I': '*',
    'j': 'k', 'J': 'k',
    'k': '~', 'K': '~',
    'l': '}', 'L': '}',
    'm': ']', 'M': ']',
    'n': '{', 'N': '{',
    'o': '[', 'O': '[',
    'p': '-', 'P': '-',
    'q': '_', 'Q': '_',
    'r': ':', 'R': ':',
    's': ',', 'S': ',',
    't': ';', 'T': ';',
    'u': '|', 'U': '|',
    'v': '°', 'V': '°',
    'w': '¬', 'W': '¬',
    'x': '#', 'X': '#',
    'y': '\$', 'Y': '\$',
    'z': '%', 'Z': '%',
    ' ': '/',
    '1': '=', '2': ')', '3': '(', '4': '&',
    '5': 'a', '6': 'b', '7': 'c', '8': 'd',
    '9': 'e', '0': 'f',
  };
  
  return input
      .split('')
      .map((ch) => map[ch] ?? 'Z') // default "Z" if not found
      .join();
}

Future<bool> mtdConfirmarDatos(BuildContext context, String vrMensaje) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
          children: [
            Icon(Icons.question_mark_sharp, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Mensaje'),
          ],
        ),
      //const Text('Confirmación'),
      content: Text(vrMensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sí'),
        ),
      ],
    ),
  ) ??
  false;
}

Future<void> mtdMessage(BuildContext context, String vrText, int vrMessageType) async {
  IconData vrIcon = Icons.info;
  Color vrColorIcon = Colors.blue;
  
  switch (vrMessageType){
    case 1: //confirmación
      vrIcon = Icons.info;
      vrColorIcon = Colors.blue; 
      break;
    case 2: //exclamación
      vrIcon = Icons.warning;
      vrColorIcon = Colors.orange; 
      break;
    case 3: //Succesful
      vrIcon = Icons.check_circle;
      vrColorIcon = Colors.green; 
      break;
    case 4: //Error 
      vrIcon = Icons.error;
      vrColorIcon = Colors.red; 
      break;
  }
  
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(vrIcon, color: vrColorIcon),
            const SizedBox(width: 8),
            const Text('Mensaje'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(vrText),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

void mtd_close_app() {
  // Preferred way:
  SystemNavigator.pop(); 

  // Or force quit (use carefully, may cause issues on iOS):
  // exit(0);
}

Future<Map<String, dynamic>?> mtdLoginRecord(String vrUsuario, String clave) async {
  //antes de logearse directo en la base de datos central
  //se probará si existen registros en la base de datos local
  //verificando si la tabla de usuarios tiene usuarios con la fecha de hoy
  bool vrHayUsuariosHoy = await DatabaseHelper().mtdDBLocalBuscarSiHayUsuariosHoy();
  
  if(vrHayUsuariosHoy)
  {
    Map<String, dynamic>? vrResultadoLocal = await DatabaseHelper().mtdDBLocalLoginRecord(vrUsuario, clave);

    return vrResultadoLocal;
  } else {
    return {"id": -1, "nombre": "No hay usuario"};
  }
}