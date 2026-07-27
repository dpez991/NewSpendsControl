import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
