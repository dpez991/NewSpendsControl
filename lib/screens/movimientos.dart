import 'package:flutter/material.dart';
import '../base/database.dart';
import '../models/mtd.dart';

class Movimientos extends StatefulWidget {
  const Movimientos({super.key});

  @override
  State<Movimientos> createState() => _MovimientosState();
}

class _MovimientosState extends State<Movimientos> {
  final _db = DatabaseHelper();

  List<Map<String, dynamic>> _lista = [];
  List<Map<String, dynamic>> _categoriasCompletas = [];
  bool _isLoading = true;

  List<String> get _categorias =>
      _categoriasCompletas.map((c) => c['DESCRIPCION'] as String).toList();

  int _idDeCategoria(String nombre) {
    final cat = _categoriasCompletas.firstWhere(
      (c) => c['DESCRIPCION'] == nombre,
      orElse: () => {'ID': -1},
    );
    return (cat['ID'] as int?) ?? -1;
  }

  String _tipoDeCategoria(Map<String, dynamic> cat) =>
      (cat['ID_TIPO'] as int?) == 1 ? 'Ingreso' : 'Gasto';

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    await _cargarCategorias();
    await _cargarMovimientos();
  }

  Future<void> _cargarCategorias() async {
    try {
      final rows = await _db.obtenerCategoriasCompletas();
      if (!mounted) return;
      setState(() => _categoriasCompletas = rows);
    } catch (_) {}
  }

  Future<void> _cargarMovimientos() async {
    try {
      final rows = await _db.obtenerMovimientosCompletos();
      if (!mounted) return;
      setState(() {
        _lista = rows;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _insertarMovimiento({
    required int idCategoria,
    required double valor,
    required String fecha,
    required String comentario,
  }) async {
    await _db.insertarMovimiento(
      idCategoria: idCategoria,
      valor: valor,
      fecha: fecha,
      comentario: comentario,
    );
  }

  Future<void> _actualizarMovimiento({
    required int id,
    required int idCategoria,
    required double valor,
    required String fecha,
    required String comentario,
  }) async {
    await _db.actualizarMovimiento(
      id: id,
      idCategoria: idCategoria,
      valor: valor,
      fecha: fecha,
      comentario: comentario,
    );
  }

  Future<void> _eliminarMovimiento(int id) async {
    await _db.eliminarMovimiento(id);
    await _cargarMovimientos();
    if (!mounted) return;
    await mtdMessage(context, 'Movimiento eliminado correctamente.', 3);
  }

  String _formatearFecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _mostrarFecha(String? f) {
    if (f == null || f.isEmpty) return '';
    try {
      final p = DateTime.parse(f);
      return '${p.day}/${p.month}/${p.year}';
    } catch (_) {
      return f;
    }
  }

  DateTime _parsearFecha(String? f) {
    if (f == null || f.isEmpty) return DateTime.now();
    try { return DateTime.parse(f); } catch (_) { return DateTime.now(); }
  }

  void _abrirFormulario({Map<String, dynamic>? movimiento}) {
    final esEdicion = movimiento != null;

    final catInicial = esEdicion
        ? (movimiento['categoria'] as String? ?? (_categorias.isNotEmpty ? _categorias.first : ''))
        : (_categorias.isNotEmpty ? _categorias.first : '');

    final catMapInicial = _categoriasCompletas.firstWhere(
      (c) => c['DESCRIPCION'] == catInicial,
      orElse: () => _categoriasCompletas.isNotEmpty ? _categoriasCompletas.first : {'ID': -1, 'DESCRIPCION': '', 'ID_TIPO': 2},
    );

    String categoriaSeleccionada = catInicial;
    String tipoSeleccionado = esEdicion
        ? ((movimiento['id_tipo'] as int?) == 1 ? 'Ingreso' : 'Gasto')
        : _tipoDeCategoria(catMapInicial);

    final txtMonto = TextEditingController(
      text: esEdicion ? (movimiento['monto'] as num).toStringAsFixed(2) : '',
    );
    final txtDescripcion = TextEditingController(
      text: esEdicion ? (movimiento['descripcion'] ?? '') : '',
    );
    DateTime fechaSeleccionada = esEdicion
        ? _parsearFecha(movimiento['fecha'] as String?)
        : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.only(
            top: 24, left: 24, right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 50, height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                )),
                const SizedBox(height: 20),
                Text(
                  esEdicion ? '✏️ Editar Movimiento' : '➕ Nuevo Movimiento',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
                ),
                const SizedBox(height: 20),

                // ── Gasto / Ingreso ──
                Row(children: [
                  Expanded(child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: tipoSeleccionado == 'Gasto' ? const Color(0xFFFF6B6B) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(color: Colors.transparent, child: InkWell(
                      onTap: null,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(child: Text('💰 Gasto', style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15,
                          color: tipoSeleccionado == 'Gasto' ? Colors.white : Colors.grey.shade600,
                        ))),
                      ),
                    )),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: tipoSeleccionado == 'Ingreso' ? const Color(0xFF51CF66) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(color: Colors.transparent, child: InkWell(
                      onTap: null,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(child: Text('💵 Ingreso', style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15,
                          color: tipoSeleccionado == 'Ingreso' ? Colors.white : Colors.grey.shade600,
                        ))),
                      ),
                    )),
                  )),
                ]),
                const SizedBox(height: 18),

                // ── Monto ──
                TextField(
                  controller: txtMonto,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Color(0xFF1F1F1F)),
                  decoration: _inputDeco('Monto (L.)', Icons.attach_money, const Color(0xFF4C8FFF)),
                ),
                const SizedBox(height: 14),

                // ── Categoría ──
                DropdownButtonFormField<String>(
                  initialValue: categoriaSeleccionada.isEmpty ? null : categoriaSeleccionada,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF7C3AED)),
                  iconSize: 28,
                  style: const TextStyle(color: Color(0xFF1F1F1F), fontSize: 16),
                  dropdownColor: Colors.white,
                  decoration: _inputDeco('Categoría', Icons.label, const Color(0xFF7C3AED)),
                  items: _categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    final catMap = _categoriasCompletas.firstWhere(
                      (c) => c['DESCRIPCION'] == val,
                      orElse: () => {'ID_TIPO': 2},
                    );
                    setModal(() {
                      categoriaSeleccionada = val;
                      tipoSeleccionado = _tipoDeCategoria(catMap);
                    });
                  },
                ),
                const SizedBox(height: 14),

                // ── Fecha ──
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fechaSeleccionada,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(primary: Color(0xFF4C8FFF), onPrimary: Colors.white),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setModal(() => fechaSeleccionada = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF4C8FFF), size: 20),
                      const SizedBox(width: 12),
                      Text('Fecha: ${_mostrarFecha(_formatearFecha(fechaSeleccionada))}',
                        style: const TextStyle(fontSize: 16, color: Color(0xFF1F1F1F))),
                      const Spacer(),
                      Icon(Icons.edit_calendar, color: Colors.grey.shade400, size: 18),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Descripción ──
                TextField(
                  controller: txtDescripcion,
                  maxLines: 3,
                  style: const TextStyle(color: Color(0xFF1F1F1F)),
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.notes, color: Color(0xFF4C8FFF)),
                    ),
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4C8FFF), width: 2)),
                    filled: true, fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Guardar ──
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: esEdicion ? const Color(0xFF7C3AED) : const Color(0xFF4C8FFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      // ── Validación de monto ──
                      final textoMonto = txtMonto.text.trim();
                      if (textoMonto.isEmpty) {
                        await mtdMessage(context, 'El monto no puede estar vacío.', 2);
                        return;
                      }
                      final monto = double.tryParse(textoMonto);
                      if (monto == null) {
                        await mtdMessage(context, 'El monto ingresado no es un número válido.', 2);
                        return;
                      }
                      if (monto < 0) {
                        await mtdMessage(context, 'El monto no puede ser negativo.', 2);
                        return;
                      }
                      if (monto == 0) {
                        await mtdMessage(context, 'El monto debe ser mayor que cero.', 2);
                        return;
                      }
                      // ── Validación de categoría ──
                      if (categoriaSeleccionada.isEmpty) {
                        await mtdMessage(context, 'Debe seleccionar una categoría.', 2);
                        return;
                      }
                      final idCat = _idDeCategoria(categoriaSeleccionada);
                      if (idCat == -1) {
                        await mtdMessage(context, 'La categoría seleccionada no es válida.', 2);
                        return;
                      }
                      // ── Guardar movimiento ──
                      if (esEdicion) {
                        await _actualizarMovimiento(
                          id: movimiento['id'] as int,
                          idCategoria: idCat,
                          valor: monto,
                          fecha: _formatearFecha(fechaSeleccionada),
                          comentario: txtDescripcion.text.trim(),
                        );
                      } else {
                        await _insertarMovimiento(
                          idCategoria: idCat,
                          valor: monto,
                          fecha: _formatearFecha(fechaSeleccionada),
                          comentario: txtDescripcion.text.trim(),
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                      await _cargarMovimientos();
                    },
                    child: Text(
                      esEdicion ? '✓ Guardar Cambios' : '✓ Agregar Movimiento',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, Color color) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color),
      labelStyle: TextStyle(color: Colors.grey.shade600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 2)),
      filled: true, fillColor: Colors.white,
    );
  }

  // Redondea a 2 decimales para evitar errores de punto flotante IEEE 754
  // que podrían hacer que un balance visual de L. 0.00 tenga signo negativo.
  double _calcularBalance() {
    double total = 0.0;
    for (final m in _lista) {
      final esIngreso = (m['id_tipo'] as int?) == 1;
      total += esIngreso
          ? (m['monto'] as num).toDouble()
          : -(m['monto'] as num).toDouble();
    }
    return double.parse(total.toStringAsFixed(2));
  }

  void _mostrarOpciones(Map<String, dynamic> mov) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: const Color(0xFFFAFAFA),
      builder: (context) => SafeArea(
        child: Wrap(children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mov['categoria'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F1F1F))),
              const SizedBox(height: 4),
              Text('L. ${(mov['monto'] as num).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: (mov['id_tipo'] as int?) == 1 ? const Color(0xFF51CF66) : const Color(0xFFFF6B6B),
                )),
            ]),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFF7C3AED)),
            title: const Text('Modificar', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); _abrirFormulario(movimiento: mov); },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Color(0xFFFF6B6B)),
            title: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFFF6B6B))),
            onTap: () { Navigator.pop(context); _eliminarMovimiento(mov['id'] as int); },
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = _calcularBalance();

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      appBar: AppBar(
        title: const Text('Movimientos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF4C8FFF),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4C8FFF), Color(0xFF6EB7FF)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarMovimientos),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE8EFF8)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4C8FFF)))
            : Column(children: [
                // ── Balance ──
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: balance >= 0
                          ? [const Color(0xFF51CF66), const Color(0xFF40C057)]
                          : [const Color(0xFFFF6B6B), const Color(0xFFFA5252)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(
                      color: (balance >= 0 ? const Color(0xFF51CF66) : const Color(0xFFFF6B6B)).withAlpha(64),
                      blurRadius: 24, offset: const Offset(0, 10),
                    )],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Balance Disponible',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Text('L. ${balance.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      balance >= 0
                          ? '¡Perfecto! Tus ingresos superan los gastos.'
                          : 'Ten cuidado, tus gastos superan a tus ingresos.',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ]),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('📊 Historial Reciente',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
                      Text('${_lista.length}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4C8FFF))),
                    ],
                  ),
                ),

                Expanded(
                  child: _lista.isEmpty
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 16, offset: const Offset(0, 8))],
                            ),
                            padding: const EdgeInsets.all(26),
                            child: const Icon(Icons.inbox, size: 64, color: Color(0xFF4C8FFF)),
                          ),
                          const SizedBox(height: 18),
                          const Text('Sin movimientos',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('Agrega tu primer movimiento.',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                        ]))
                      : RefreshIndicator(
                          onRefresh: _cargarMovimientos,
                          color: const Color(0xFF4C8FFF),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            itemCount: _lista.length,
                            itemBuilder: (context, i) {
                              final m = _lista[i];
                              final esIngreso = (m['id_tipo'] as int?) == 1;
                              final color = esIngreso ? const Color(0xFF51CF66) : const Color(0xFFFF6B6B);
                              final icon = esIngreso ? Icons.trending_up : Icons.trending_down;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [BoxShadow(
                                      color: Colors.black.withAlpha(13),
                                      blurRadius: 14, offset: const Offset(0, 6),
                                    )],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _mostrarOpciones(m),
                                      borderRadius: BorderRadius.circular(18),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                        child: Row(children: [
                                          Container(
                                            width: 54, height: 54,
                                            decoration: BoxDecoration(
                                              color: color.withAlpha(46),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Icon(icon, color: color, size: 28),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(m['categoria'] ?? '',
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1F1F1F))),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_mostrarFecha(m['fecha'] as String?)}${(m['descripcion'] as String?)?.isNotEmpty == true ? ' • ${m['descripcion']}' : ''}',
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                              ),
                                            ],
                                          )),
                                          const SizedBox(width: 12),
                                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                            Text(
                                              '${esIngreso ? '+' : '-'} L. ${(m['monto'] as num).toStringAsFixed(2)}',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                                            ),
                                            const SizedBox(height: 6),
                                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                                          ]),
                                        ]),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ]),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4C8FFF),
        foregroundColor: Colors.white,
        elevation: 10,
        icon: const Icon(Icons.add, size: 28),
        label: const Text('Nuevo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        onPressed: () => _abrirFormulario(),
      ),
    );
  }
}
