import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import './mtd.dart';

class SesionProvider extends ChangeNotifier {
  Usuario? _usuario;

  Usuario? get usuario => _usuario;

  void setUsuario(Usuario user) {
    _usuario = user;
    notifyListeners();
  }

  void clearUsuario() {
    _usuario = null;
    notifyListeners();
  }
}

class Usuario {
  final String uid;    // UID generado por Firebase Authentication
  final String nombre;
  final String codigo; // Código de usuario (ya no se usa para autenticar)
  final String correo;

  Usuario({
    required this.uid,
    required this.nombre,
    required this.codigo,
    required this.correo,
  });
}

Widget clsButton(
  BuildContext context,
  VoidCallback onPressed,
  String text,
) {
  return SizedBox(
    width: MediaQuery.of(context).size.width * 0.9,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: mtd_get_color_2(),
        foregroundColor: mtd_get_color_1(),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        elevation: 6,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    ),
  );
}


Widget clsTextField(
  String mainLabel,
  TextEditingController controller,
  String labelText,
  bool obscureText,
  double spaceAfter,
  TextInputType keyboardType,
  FocusNode? focusNode,
  [Function()? onChanged,] // fix type here
) {
  final focusNode0 = focusNode ?? FocusNode();

  if (focusNode == null) {
  focusNode0.addListener(() {
  if (focusNode0.hasFocus) {
  Future.delayed(const Duration(milliseconds: 50), () {
  controller.selection = TextSelection(
  baseOffset: 0,
  extentOffset: controller.text.length,
  );
  });
  }
  });
}

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  if (mainLabel.isNotEmpty)
    clsMainLabelField(mainLabel),
  const SizedBox(height: 6),
  TextField(
  focusNode: focusNode0,
  controller: controller,
  keyboardType: keyboardType,
  obscureText: obscureText,
  inputFormatters: [
      UpperCaseTextFormatter(), // custom formatter
    ],
  onChanged: (_) => onChanged?.call(), // just pass it directly
  decoration: InputDecoration(
  labelText: labelText,
  labelStyle: GoogleFonts.dmSans(color: mtd_get_color_0()),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  filled: true,
  fillColor: mtd_get_color_2(),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  ),
  ),
  SizedBox(height: spaceAfter),
  ],
  );
}


Text clsMainLabelField(String vrMainLabel)
{
  return Text(
    vrMainLabel,
    style: GoogleFonts.dmSans(
      fontSize: 15,
      color: const Color(0xFF8F8E8E),
      fontWeight: FontWeight.w500,
    ),
  );
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(), // convert to upper case
      selection: newValue.selection, // keep cursor position
    );
  }
}

Widget clsCampoContrasena(
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