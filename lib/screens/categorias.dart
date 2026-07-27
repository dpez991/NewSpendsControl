import 'package:flutter/material.dart';
import '../base/database.dart';

class AdministracionCategorias extends StatefulWidget {
  const AdministracionCategorias({super.key});

  @override
  State<AdministracionCategorias> createState() =>
      _AdministracionCategoriasState();
}

class _AdministracionCategoriasState extends State<AdministracionCategorias> {
  final TextEditingController _buscarController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();

  List<Map<String, dynamic>> _categorias = [];

  String _busqueda = '';
  int? _categoriaSeleccionadaId;
  int _idTipoSeleccionado = 2;

  static const Color azulPrincipal = Color(0xFF4C8FFF);
  static const Color azulSecundario = Color(0xFF6EB7FF);
  static const Color verdePrincipal = Color(0xFF51CF66);
  static const Color rojoPrincipal = Color(0xFFFF6B6B);
  static const Color texto = Color(0xFF1F1F1F);

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  List<Map<String, dynamic>> get _categoriasFiltradas {
    return _categorias.where((categoria) {
      final descripcion = categoria['DESCRIPCION'].toString().toLowerCase();
      return descripcion.contains(_busqueda.toLowerCase());
    }).toList();
  }

  Future<void> _cargarCategorias() async {
    final datos = await DatabaseHelper().obtenerCategoriasCompletas();

    if (!mounted) return;

    setState(() {
      _categorias = datos;
    });
  }

  Future<void> _agregarCategoria() async {
    final nombre = _categoriaController.text.trim();

    if (nombre.isEmpty) {
      _mensaje('Escriba el nombre de la categoría.');
      return;
    }

    final existe = _categorias.any(
          (categoria) =>
      categoria['DESCRIPCION'].toString().toLowerCase() ==
          nombre.toLowerCase(),
    );

    if (existe) {
      _mensaje('Esa categoría ya existe.');
      return;
    }

    await DatabaseHelper().insertarCategoria(nombre, _idTipoSeleccionado);

    _categoriaController.clear();
    _categoriaSeleccionadaId = null;
    _idTipoSeleccionado = 2;

    await _cargarCategorias();

    _mensaje('Categoría agregada correctamente.');
  }

  Future<void> _editarCategoria() async {
    if (_categoriaSeleccionadaId == null) {
      _mensaje('Seleccione una categoría para editar.');
      return;
    }

    final nuevoNombre = _categoriaController.text.trim();

    if (nuevoNombre.isEmpty) {
      _mensaje('Escriba el nuevo nombre de la categoría.');
      return;
    }

    final existe = _categorias.any(
          (categoria) =>
      _obtenerEntero(categoria['ID']) != _categoriaSeleccionadaId &&
          categoria['DESCRIPCION'].toString().toLowerCase() ==
              nuevoNombre.toLowerCase(),
    );

    if (existe) {
      _mensaje('Ya existe una categoría con ese nombre.');
      return;
    }

    await DatabaseHelper().modificarCategoria(
      _categoriaSeleccionadaId!,
      nuevoNombre,
      _idTipoSeleccionado,
    );

    _categoriaController.clear();
    _categoriaSeleccionadaId = null;
    _idTipoSeleccionado = 2;

    await _cargarCategorias();

    _mensaje('Categoría editada correctamente.');
  }

  Future<void> _eliminarCategoria() async {
    if (_categoriaSeleccionadaId == null) {
      _mensaje('Seleccione una categoría para eliminar.');
      return;
    }

    await DatabaseHelper().eliminarCategoriaBD(_categoriaSeleccionadaId!);

    _categoriaController.clear();
    _categoriaSeleccionadaId = null;
    _idTipoSeleccionado = 2;

    await _cargarCategorias();

    _mensaje('Categoría eliminada correctamente.');
  }

  void _seleccionarCategoria(Map<String, dynamic> categoria) {
    setState(() {
      _categoriaSeleccionadaId = _obtenerEntero(categoria['ID']);
      _idTipoSeleccionado = _obtenerEntero(categoria['ID_TIPO']);
      _categoriaController.text = categoria['DESCRIPCION'].toString();
    });
  }

  int _obtenerEntero(dynamic valor) {
    if (valor is int) return valor;
    if (valor is String) return int.tryParse(valor) ?? 0;
    return 0;
  }

  Widget _selectorTipoCategoria() {
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _idTipoSeleccionado == 2
                  ? rojoPrincipal
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _idTipoSeleccionado = 2;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'Egreso',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _idTipoSeleccionado == 2
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _idTipoSeleccionado == 1
                  ? verdePrincipal
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _idTipoSeleccionado = 1;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'Ingreso',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _idTipoSeleccionado == 1
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconoCategoria(String descripcion) {
    final nombre = descripcion.toLowerCase();

    if (nombre.contains('comida')) return Icons.restaurant;
    if (nombre.contains('transporte')) return Icons.directions_bus;
    if (nombre.contains('salario')) return Icons.account_balance_wallet;
    if (nombre.contains('servicio')) return Icons.receipt_long;
    if (nombre.contains('salud')) return Icons.favorite;
    if (nombre.contains('educación')) return Icons.school;
    if (nombre.contains('compra')) return Icons.shopping_bag;
    if (nombre.contains('entretenimiento')) return Icons.movie;
    if (nombre.contains('otro')) return Icons.category;

    return Icons.category;
  }

  Color _colorCategoria(String descripcion) {
    final nombre = descripcion.toLowerCase();

    if (nombre.contains('comida')) return const Color(0xFFFF6B6B);
    if (nombre.contains('transporte')) return const Color(0xFF4C8FFF);
    if (nombre.contains('salario')) return const Color(0xFF51CF66);
    if (nombre.contains('servicio')) return const Color(0xFFFFB020);
    if (nombre.contains('salud')) return const Color(0xFFE91E63);
    if (nombre.contains('educación')) return const Color(0xFF7C3AED);
    if (nombre.contains('compra')) return const Color(0xFF00B8A9);
    if (nombre.contains('entretenimiento')) return const Color(0xFFFF8A3D);

    return const Color(0xFF6B7280);
  }

  void _mensaje(String textoMensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(textoMensaje),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _buscarController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categorias = _categoriasFiltradas;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      appBar: AppBar(
        title: const Text(
          'Categorías',
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE8EFF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF51CF66), Color(0xFF40C057)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: verdePrincipal.withAlpha(65),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Administración de categorías',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Organiza tus gastos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_categorias.length} categorías registradas',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _categoriaController,
                        decoration: InputDecoration(
                          hintText: 'Escriba una categoría',
                          prefixIcon: const Icon(
                            Icons.label,
                            color: Color(0xFF7C3AED),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _agregarCategoria,
                      icon: const Icon(Icons.add, size: 22),
                      label: const Text(
                        'Agregar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulPrincipal,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: azulPrincipal.withAlpha(90),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                _selectorTipoCategoria(),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _editarCategoria,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text(
                          'Editar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                          side: const BorderSide(
                            color: Color(0xFF7C3AED),
                            width: 1.5,
                          ),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _eliminarCategoria,
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text(
                          'Eliminar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: rojoPrincipal,
                          side: const BorderSide(
                            color: rojoPrincipal,
                            width: 1.5,
                          ),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                TextField(
                  controller: _buscarController,
                  decoration: InputDecoration(
                    hintText: 'Buscar Categoría',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: azulPrincipal,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _busqueda = value;
                      _categoriaSeleccionadaId = null;
                      _idTipoSeleccionado = 2;
                      _categoriaController.clear();
                    });
                  },
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📋 Lista de Categorías',
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

                const SizedBox(height: 14),

                if (categorias.isEmpty)
                  Container(
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
                        const Icon(
                          Icons.inbox,
                          size: 56,
                          color: azulPrincipal,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay categorías registradas.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    itemCount: categorias.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final categoria = categorias[index];
                      final id = _obtenerEntero(categoria['ID']);
                      final descripcion =
                      categoria['DESCRIPCION'].toString();
                      final idTipo = _obtenerEntero(categoria['ID_TIPO']);
                      final esIngreso = idTipo == 1;

                      final seleccionada = _categoriaSeleccionadaId == id;
                      final colorCategoria =
                          esIngreso ? verdePrincipal : _colorCategoria(descripcion);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: seleccionada
                                  ? colorCategoria
                                  : Colors.transparent,
                              width: 1.7,
                            ),
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
                              onTap: () => _seleccionarCategoria(categoria),
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: colorCategoria.withAlpha(45),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        _iconoCategoria(descripcion),
                                        color: colorCategoria,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            descripcion,
                                            style: TextStyle(
                                              fontWeight: seleccionada
                                                  ? FontWeight.w800
                                                  : FontWeight.w700,
                                              fontSize: 16,
                                              color: texto,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: (esIngreso
                                                      ? verdePrincipal
                                                      : rojoPrincipal)
                                                  .withAlpha(25),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              esIngreso ? 'Ingreso' : 'Egreso',
                                              style: TextStyle(
                                                color: esIngreso
                                                    ? verdePrincipal
                                                    : rojoPrincipal,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      seleccionada
                                          ? Icons.check_circle
                                          : Icons.arrow_forward_ios,
                                      size: seleccionada ? 24 : 16,
                                      color: seleccionada
                                          ? colorCategoria
                                          : Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
