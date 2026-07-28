import 'package:flutter/material.dart';
import '../base/database.dart';
import '../models/mtd.dart';

class PresupuestoScreen extends StatefulWidget {
  const PresupuestoScreen({super.key});

  @override
  State<PresupuestoScreen> createState() => _PresupuestoScreenState();
}

class _PresupuestoScreenState extends State<PresupuestoScreen> {
  final TextEditingController totalController = TextEditingController();

  final Map<String, TextEditingController> controladoresCategoria = {};
  final Map<String, double> gastosPorCategoria = {};
  final Map<String, int> idsPorCategoria = {};

  DateTime fechaSeleccionada = DateTime.now();

  double totalPresupuesto = 0.0;
  double totalAsignado = 0.0;
  bool cargando = true;

  List<String> categorias = [];

  static const Color azulPrincipal = Color(0xFF4C8FFF);
  static const Color azulSecundario = Color(0xFF6EB7FF);
  static const Color verdePrincipal = Color(0xFF51CF66);
  static const Color rojoPrincipal = Color(0xFFFF6B6B);
  static const Color moradoPrincipal = Color(0xFF7C3AED);
  static const Color texto = Color(0xFF1F1F1F);

  final List<String> meses = [
    "ENERO",
    "FEBRERO",
    "MARZO",
    "ABRIL",
    "MAYO",
    "JUNIO",
    "JULIO",
    "AGOSTO",
    "SEPTIEMBRE",
    "OCTUBRE",
    "NOVIEMBRE",
    "DICIEMBRE",
  ];

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    if (mounted) {
      setState(() {
        cargando = true;
      });
    }

    final repo = DatabaseHelper();

    final categoriasDB = await repo.getCategoriasEgresos();

    final presupuesto = await repo.obtenerPresupuestoMensual(
      anio: fechaSeleccionada.year,
      mes: fechaSeleccionada.month,
    );

    final presupuestosCategorias = await repo.obtenerPresupuestoCategorias(
      anio: fechaSeleccionada.year,
      mes: fechaSeleccionada.month,
    );

    final Map<String, double> mapaPresupuestos = {};
    final Map<String, int> mapaIdsCategorias = {};

    for (final row in presupuestosCategorias) {
      final categoria = row['categoria'].toString();

      mapaIdsCategorias[categoria] =
          int.tryParse(row['id_categoria'].toString()) ?? 0;

      mapaPresupuestos[categoria] =
          double.tryParse(row['valor'].toString()) ?? 0.0;
    }

    double sumaAsignada = 0.0;
    final Map<String, double> gastosTemp = {};

    for (final categoria in categoriasDB) {
      final valor = mapaPresupuestos[categoria] ?? 0.0;
      sumaAsignada += valor;

      controladoresCategoria[categoria] ??= TextEditingController();
      controladoresCategoria[categoria]!.text = valor.toStringAsFixed(2);

      gastosTemp[categoria] = await repo.obtenerTotalGastosPorCategoria(
        categoria,
        fechaSeleccionada.year,
        fechaSeleccionada.month,
      );
    }

    if (!mounted) return;

    setState(() {
      categorias = categoriasDB;
      totalPresupuesto = presupuesto;
      totalAsignado = sumaAsignada;
      gastosPorCategoria
        ..clear()
        ..addAll(gastosTemp);
      idsPorCategoria
        ..clear()
        ..addAll(mapaIdsCategorias);
      totalController.text = presupuesto.toStringAsFixed(2);
      cargando = false;
    });
  }

  Future<void> guardarTodo() async {
    // ── Validación del presupuesto total ──
    final textoTotal = totalController.text.replaceAll(',', '').trim();
    if (textoTotal.isEmpty) {
      await mtdMessage(context, 'El monto del presupuesto no puede estar vacío.', 2);
      return;
    }
    final valorTotal = double.tryParse(textoTotal) ?? 0.0;
    if (valorTotal <= 0) {
      await mtdMessage(context, 'El presupuesto mensual debe ser mayor que cero.', 2);
      return;
    }

    final repo = DatabaseHelper();

    await repo.guardarPresupuestoMensual(
      anio: fechaSeleccionada.year,
      mes: fechaSeleccionada.month,
      valor: valorTotal,
    );

    for (final categoria in categorias) {
      final texto = controladoresCategoria[categoria]!
          .text
          .replaceAll(',', '')
          .trim();

      final valor = double.tryParse(texto) ?? 0.0;

      await repo.guardarPresupuestoCategoria(
        anio: fechaSeleccionada.year,
        mes: fechaSeleccionada.month,
        idCategoria: idsPorCategoria[categoria] ?? 0,
        valor: valor,
      );
    }

    await cargarDatos();

    if (!mounted) return;

    await mtdMessage(context, 'Presupuesto guardado correctamente.', 3);
  }

  void mesAnterior() {
    setState(() {
      fechaSeleccionada = DateTime(
        fechaSeleccionada.year,
        fechaSeleccionada.month - 1,
      );
    });

    cargarDatos();
  }

  void mesSiguiente() {
    setState(() {
      fechaSeleccionada = DateTime(
        fechaSeleccionada.year,
        fechaSeleccionada.month + 1,
      );
    });

    cargarDatos();
  }

  IconData _iconoCategoria(String descripcion) {
    final nombre = descripcion.toLowerCase();

    if (nombre.contains('comida')) return Icons.restaurant;
    if (nombre.contains('transporte')) return Icons.directions_bus;
    if (nombre.contains('salario')) return Icons.account_balance_wallet;
    if (nombre.contains('servicio')) return Icons.receipt_long;
    if (nombre.contains('salud')) return Icons.favorite;
    if (nombre.contains('educ')) return Icons.school;
    if (nombre.contains('compra')) return Icons.shopping_bag;
    if (nombre.contains('entretenimiento')) return Icons.movie;

    return Icons.category;
  }

  Color _colorCategoria(String descripcion) {
    final nombre = descripcion.toLowerCase();

    if (nombre.contains('comida')) return rojoPrincipal;
    if (nombre.contains('transporte')) return azulPrincipal;
    if (nombre.contains('salario')) return verdePrincipal;
    if (nombre.contains('servicio')) return const Color(0xFFFFB020);
    if (nombre.contains('salud')) return const Color(0xFFE91E63);
    if (nombre.contains('educ')) return moradoPrincipal;
    if (nombre.contains('compra')) return const Color(0xFF00B8A9);
    if (nombre.contains('entretenimiento')) return const Color(0xFFFF8A3D);

    return const Color(0xFF6B7280);
  }

  @override
  void dispose() {
    totalController.dispose();

    for (final controller in controladoresCategoria.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Redondea antes de comparar para evitar errores de punto flotante
    // que podrían hacer que L. 0.00 visual aparezca con gradiente negativo.
    final disponible = double.parse(
      (totalPresupuesto - totalAsignado).toStringAsFixed(2),
    );
    final nombreMes = meses[fechaSeleccionada.month - 1];
    final progresoAsignado =
        totalPresupuesto > 0 ? (totalAsignado / totalPresupuesto) : 0.0;
    final progresoVisual = progresoAsignado.clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      appBar: AppBar(
        title: const Text(
          'Presupuesto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: azulPrincipal,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [azulPrincipal, azulSecundario],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // actions: [
        //   IconButton(
        //     onPressed: cargarDatos,
        //     icon: const Icon(Icons.refresh, color: Colors.white),
        //   ),
        // ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE8EFF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: cargando
            ? const Center(
                child: CircularProgressIndicator(color: azulPrincipal),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _resumenMensual(
                        nombreMes: nombreMes,
                        disponible: disponible,
                        progresoVisual: progresoVisual,
                      ),
                      const SizedBox(height: 16),
                      _selectorMes(nombreMes),
                      const SizedBox(height: 16),
                      _capturaPresupuesto(),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '📋 Lista de Categorías de gastos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: texto,
                            ),
                          ),
                          Text(
                            '${categorias.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: azulPrincipal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (categorias.isEmpty)
                        _estadoVacio()
                      else
                        ...categorias.map((categoria) {
                          final controller = controladoresCategoria[categoria]!;
                          final gasto = gastosPorCategoria[categoria] ?? 0.0;
                          final presupuestoCategoria =
                              double.tryParse(controller.text) ?? 0.0;

                          double progreso = 0.0;

                          if (presupuestoCategoria > 0) {
                            progreso = gasto / presupuestoCategoria;
                          }

                          if (progreso > 1) {
                            progreso = 1;
                          }

                          return _categoriaEditable(
                            categoria: categoria,
                            controller: controller,
                            gastado: gasto,
                            progreso: progreso,
                            presupuesto: presupuestoCategoria,
                            color: _colorCategoria(categoria),
                            icono: _iconoCategoria(categoria),
                          );
                        }),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: azulPrincipal,
        foregroundColor: Colors.white,
        elevation: 10,
        icon: const Icon(Icons.save),
        label: const Text(
          'Guardar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onPressed: guardarTodo,
      ),
    );
  }

  Widget _resumenMensual({
    required String nombreMes,
    required double disponible,
    required double progresoVisual,
  }) {
    final disponiblePositivo = disponible >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: disponiblePositivo
              ? [verdePrincipal, const Color(0xFF40C057)]
              : [rojoPrincipal, const Color(0xFFFA5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (disponiblePositivo ? verdePrincipal : rojoPrincipal)
                .withAlpha(65),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$nombreMes ${fechaSeleccionada.year}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'L. ${disponible.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Disponible para asignar',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progresoVisual,
              minHeight: 9,
              color: Colors.white,
              backgroundColor: Colors.white.withAlpha(65),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _montoResumen(
                  titulo: 'Presupuesto',
                  valor: totalPresupuesto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _montoResumen(
                  titulo: 'Asignado',
                  valor: totalAsignado,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _montoResumen({
    required String titulo,
    required double valor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'L. ${valor.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectorMes(String nombreMes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: mesAnterior,
            icon: const Icon(Icons.chevron_left),
            color: azulPrincipal,
          ),
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.calendar_month, color: moradoPrincipal),
                const SizedBox(height: 4),
                Text(
                  nombreMes,
                  style: const TextStyle(
                    color: texto,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${fechaSeleccionada.year}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: mesSiguiente,
            icon: const Icon(Icons.chevron_right),
            color: azulPrincipal,
          ),
        ],
      ),
    );
  }

  Widget _capturaPresupuesto() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total presupuesto',
            style: TextStyle(
              color: texto,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: totalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monto mensual',
              prefixText: 'L. ',
              prefixIcon: const Icon(Icons.account_balance_wallet,
                  color: azulPrincipal),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: azulPrincipal, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoVacio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox, size: 56, color: azulPrincipal),
          const SizedBox(height: 12),
          Text(
            'No hay categorias para presupuestar.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoriaEditable({
    required String categoria,
    required TextEditingController controller,
    required double gastado,
    required double progreso,
    required double presupuesto,
    required Color color,
    required IconData icono,
  }) {
    // Redondea para evitar que errores de punto flotante inviertan la
    // etiqueta 'Libre'/'Exceso' o el color verde/rojo de la categoría.
    final disponible = double.parse(
      (presupuesto - gastado).toStringAsFixed(2),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withAlpha(45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icono, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          categoria,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: texto,
                          ),
                        ),
                      ),
                      Text(
                        '${(progreso * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Presupuesto',
                      prefixText: 'L. ',
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: color, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progreso,
                      minHeight: 7,
                      color: color,
                      backgroundColor: color.withAlpha(35),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _detalleCategoria(
                        titulo: 'Gastado',
                        valor: gastado,
                        color: rojoPrincipal,
                      ),
                      _detalleCategoria(
                        titulo: disponible >= 0 ? 'Libre' : 'Exceso',
                        valor: disponible.abs(),
                        color: disponible >= 0 ? verdePrincipal : rojoPrincipal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detalleCategoria({
    required String titulo,
    required double valor,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$titulo: L. ${valor.toStringAsFixed(2)}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
