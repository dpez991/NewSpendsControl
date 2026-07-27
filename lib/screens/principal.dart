import 'package:flutter/material.dart';
import '../base/database.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final _db = DatabaseHelper();

  List<Map<String, dynamic>> _movimientos = [];
  List<Map<String, dynamic>> _categoriasCompletas = [];
  bool _cargando = true;

  static const Color azulPrincipal = Color(0xFF4C8FFF);
  static const Color azulSecundario = Color(0xFF6EB7FF);
  static const Color verdePrincipal = Color(0xFF51CF66);
  static const Color rojoPrincipal = Color(0xFFFF6B6B);
  static const Color moradoPrincipal = Color(0xFF7C3AED);
  static const Color texto = Color(0xFF1F1F1F);

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
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (mounted) {
      setState(() => _cargando = true);
    }

    await _cargarCategorias();
    await _cargarMovimientos();

    if (mounted) {
      setState(() => _cargando = false);
    }
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
      final db = await _db.database;
      final rows = await db.rawQuery('''
        SELECT
          A.ID          as id,
          A.VALOR       as monto,
          A.FECHA       as fecha,
          A.COMENTARIO  as descripcion,
          B.ID          as id_categoria,
          B.DESCRIPCION as categoria,
          B.ID_TIPO     as id_tipo
        FROM MOVIMIENTOS_X_USUARIO A
        INNER JOIN MOVIMIENTOS_CATEGORIAS B ON A.ID_CATEGORIA = B.ID
        WHERE A.ESTADO = 1
        ORDER BY A.ID DESC
      ''');
      if (!mounted) return;
      setState(() => _movimientos = rows);
    } catch (_) {}
  }

  String get _fechaHoy {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get _fechaHoyMostrar {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  double get _ingresosHoy => _movimientos
      .where((m) => (m['id_tipo'] as int?) == 1 && m['fecha'] == _fechaHoy)
      .fold(0.0, (sum, m) => sum + (m['monto'] as num).toDouble());

  double get _gastosHoy => _movimientos
      .where((m) => (m['id_tipo'] as int?) == 2 && m['fecha'] == _fechaHoy)
      .fold(0.0, (sum, m) => sum + (m['monto'] as num).toDouble());

  double get _saldoActual => _ingresosHoy - _gastosHoy;

  List<Map<String, dynamic>> get _recientes => _movimientos.take(5).toList();

  void _abrirAgregarMovimiento() {
    final catInicial = _categorias.isNotEmpty ? _categorias.first : '';
    final catMapInicial = _categoriasCompletas.isNotEmpty
        ? _categoriasCompletas.first
        : <String, dynamic>{};

    String categoriaSeleccionada = catInicial;
    String tipoSeleccionado =
        catMapInicial.isNotEmpty ? _tipoDeCategoria(catMapInicial) : 'Gasto';

    final txtMonto = TextEditingController();
    final txtDescripcion = TextEditingController();
    DateTime fechaSeleccionada = DateTime.now();

    String formatearFecha(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    String mostrarFecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

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
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nuevo Movimiento',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: texto,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _selectorTipoMovimiento(
                        activo: tipoSeleccionado == 'Gasto',
                        textoBoton: 'Gasto',
                        color: rojoPrincipal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _selectorTipoMovimiento(
                        activo: tipoSeleccionado == 'Ingreso',
                        textoBoton: 'Ingreso',
                        color: verdePrincipal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: txtMonto,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: texto),
                  decoration:
                      _inputDeco('Monto (L.)', Icons.attach_money, azulPrincipal),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue:
                      categoriaSeleccionada.isEmpty ? null : categoriaSeleccionada,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down,
                      color: moradoPrincipal),
                  iconSize: 28,
                  style: const TextStyle(color: texto, fontSize: 16),
                  dropdownColor: Colors.white,
                  decoration:
                      _inputDeco('Categoria', Icons.label, moradoPrincipal),
                  items: _categorias
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ))
                      .toList(),
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
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fechaSeleccionada,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: azulPrincipal,
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setModal(() => fechaSeleccionada = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: azulPrincipal, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Fecha: ${mostrarFecha(fechaSeleccionada)}',
                          style: const TextStyle(fontSize: 16, color: texto),
                        ),
                        const Spacer(),
                        Icon(Icons.edit_calendar,
                            color: Colors.grey.shade400, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: txtDescripcion,
                  maxLines: 3,
                  style: const TextStyle(color: texto),
                  decoration: InputDecoration(
                    labelText: 'Descripcion (opcional)',
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.notes, color: azulPrincipal),
                    ),
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: azulPrincipal, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulPrincipal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      final monto = double.tryParse(txtMonto.text);
                      if (monto == null || monto <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ingresa un monto valido'),
                          ),
                        );
                        return;
                      }

                      final idCat = _idDeCategoria(categoriaSeleccionada);
                      if (idCat == -1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selecciona una categoria'),
                          ),
                        );
                        return;
                      }

                      final db = await _db.database;
                      await db.insert('MOVIMIENTOS_X_USUARIO', {
                        'ID_CATEGORIA': idCat,
                        'VALOR': monto,
                        'FECHA': formatearFecha(fechaSeleccionada),
                        'COMENTARIO': txtDescripcion.text.trim(),
                        'ESTADO': 1,
                      });

                      if (context.mounted) Navigator.pop(context);
                      await _cargarMovimientos();
                    },
                    child: const Text(
                      'Agregar Movimiento',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _selectorTipoMovimiento({
    required bool activo,
    required String textoBoton,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: activo ? color : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                textoBoton,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: activo ? Colors.white : Colors.grey.shade600,
                ),
              ),
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      appBar: AppBar(
        title: const Text(
          'Inicio',
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
        actions: [
          IconButton(
            onPressed: _cargarDatos,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE8EFF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: azulPrincipal))
            : SafeArea(
                child: RefreshIndicator(
                  color: azulPrincipal,
                  onRefresh: _cargarDatos,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      _balanceCard(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              titulo: 'Ingresos',
                              valor: _ingresosHoy,
                              icono: Icons.trending_up,
                              color: verdePrincipal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              titulo: 'Gastos',
                              valor: _gastosHoy,
                              icono: Icons.trending_down,
                              color: rojoPrincipal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Movimientos recientes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: texto,
                            ),
                          ),
                          Text(
                            '${_recientes.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: azulPrincipal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_recientes.isEmpty)
                        _estadoVacio()
                      else
                        ..._recientes.map(_movimientoCard),
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
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          'Nuevo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onPressed: _abrirAgregarMovimiento,
      ),
    );
  }

  Widget _balanceCard() {
    final positivo = _saldoActual >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: positivo
              ? [verdePrincipal, const Color(0xFF40C057)]
              : [rojoPrincipal, const Color(0xFFFA5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (positivo ? verdePrincipal : rojoPrincipal).withAlpha(65),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fechaHoyMostrar,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'L. ${_saldoActual.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            positivo
                ? 'Tu balance de hoy va saludable.'
                : 'Tus gastos superan tus ingresos de hoy.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String titulo,
    required double valor,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withAlpha(45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, color: color, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'L. ${valor.toStringAsFixed(2)}',
            style: const TextStyle(
              color: texto,
              fontSize: 20,
              fontWeight: FontWeight.w800,
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
            'No hay movimientos aun.',
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

  Widget _movimientoCard(Map<String, dynamic> movimiento) {
    final esIngreso = (movimiento['id_tipo'] as int?) == 1;
    final color = esIngreso ? verdePrincipal : rojoPrincipal;
    final icono = esIngreso ? Icons.trending_up : Icons.trending_down;
    String fecha = movimiento['fecha'] ?? '';

    try {
      final d = DateTime.parse(fecha);
      fecha = '${d.day}/${d.month}/${d.year}';
    } catch (_) {}

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
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
                      Text(
                        movimiento['categoria'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: texto,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fecha,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${esIngreso ? '+' : '-'} L. ${(movimiento['monto'] as num).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
