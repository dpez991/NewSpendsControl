import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Reemplaza a DatabaseHelper.
/// Toda la persistencia se realiza en Cloud Firestore bajo /usuarios/{uid}/.
class FirestoreHelper {
  static final FirestoreHelper _instance = FirestoreHelper._internal();
  factory FirestoreHelper() => _instance;
  FirestoreHelper._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// UID del usuario actualmente autenticado.
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── Referencias a sub-colecciones ──────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _categorias =>
      _db.collection('usuarios').doc(_uid).collection('categorias');

  CollectionReference<Map<String, dynamic>> get _movimientos =>
      _db.collection('usuarios').doc(_uid).collection('movimientos');

  CollectionReference<Map<String, dynamic>> get _presupuestoMensual =>
      _db.collection('usuarios').doc(_uid).collection('presupuesto_mensual');

  CollectionReference<Map<String, dynamic>> get _presupuestoCategorias =>
      _db.collection('usuarios').doc(_uid).collection('presupuesto_categorias');

  // ── Inicialización: categorías semilla ─────────────────────────────────────

  /// Crea las categorías predeterminadas si el usuario no tiene ninguna aún.
  /// Reemplaza los INSERT semilla del onCreate de SQLite.
  Future<void> inicializarCategoriasSiEsNecesario() async {
    final snap = await _categorias.limit(1).get();
    if (snap.docs.isNotEmpty) return; // Ya tiene categorías — no hacer nada

    final batch = _db.batch();
    final semillas = [
      {'descripcion': 'Comida',     'idTipo': 2},
      {'descripcion': 'Transporte', 'idTipo': 2},
      {'descripcion': 'Salario',    'idTipo': 1},
    ];
    for (final s in semillas) {
      final ref = _categorias.doc();
      batch.set(ref, {
        ...s,
        'estado': 1,
        'creadoEn': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ── Categorías ──────────────────────────────────────────────────────────────

  /// Devuelve todas las categorías activas ordenadas por descripción.
  /// Las claves del mapa son compatibles con las pantallas existentes:
  ///   'ID'          → docId de Firestore (String)
  ///   'DESCRIPCION' → nombre de la categoría
  ///   'ID_TIPO'     → 1 = Ingreso, 2 = Egreso
  ///   'ESTADO'      → 1 = activo
  Future<List<Map<String, dynamic>>> obtenerCategoriasCompletas() async {
    final snap = await _categorias
        .where('estado', isEqualTo: 1)
        .orderBy('descripcion')
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return <String, dynamic>{
        'ID':          doc.id,
        'DESCRIPCION': data['descripcion'] ?? '',
        'ID_TIPO':     (data['idTipo'] as num?)?.toInt() ?? 2,
        'ESTADO':      (data['estado'] as num?)?.toInt() ?? 1,
      };
    }).toList();
  }

  /// Devuelve únicamente los nombres de categorías activas (todos los tipos).
  Future<List<String>> getCategorias() async {
    final rows = await obtenerCategoriasCompletas();
    return rows.map((r) => r['DESCRIPCION'] as String).toList();
  }

  /// Devuelve únicamente los nombres de categorías de tipo Egreso (idTipo=2).
  Future<List<String>> getCategoriasEgresos() async {
    final snap = await _categorias
        .where('estado', isEqualTo: 1)
        .where('idTipo', isEqualTo: 2)
        .orderBy('descripcion')
        .get();

    return snap.docs
        .map((doc) => doc.data()['descripcion'] as String? ?? '')
        .toList();
  }

  /// Inserta una nueva categoría.
  Future<void> insertarCategoria(String descripcion, int idTipo) async {
    await _categorias.add({
      'descripcion': descripcion.trim(),
      'idTipo':      idTipo,
      'estado':      1,
      'creadoEn':    FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza descripción y tipo de una categoría existente.
  Future<void> modificarCategoria(
    String id,
    String descripcion,
    int idTipo,
  ) async {
    await _categorias.doc(id).update({
      'descripcion': descripcion.trim(),
      'idTipo':      idTipo,
    });
  }

  /// Baja lógica de categoría (estado = 2).
  Future<void> eliminarCategoriaBD(String id) async {
    await _categorias.doc(id).update({'estado': 2});
  }

  // ── Movimientos ─────────────────────────────────────────────────────────────

  /// Devuelve todos los movimientos activos ordenados por fecha de creación DESC.
  /// La descripción y tipo de categoría van desnormalizados en cada documento
  /// para evitar el JOIN que SQLite realizaba en rawQuery.
  /// Claves del mapa compatibles con las pantallas existentes:
  ///   'id'          → docId de Firestore (String)
  ///   'monto'       → double
  ///   'fecha'       → String YYYY-MM-DD
  ///   'descripcion' → comentario del movimiento
  ///   'id_categoria'→ docId de la categoría (String)
  ///   'categoria'   → nombre de la categoría
  ///   'id_tipo'     → 1 = Ingreso, 2 = Egreso
  Future<List<Map<String, dynamic>>> obtenerMovimientosCompletos() async {
    final snap = await _movimientos
        .where('estado', isEqualTo: 1)
        .orderBy('creadoEn', descending: true)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return <String, dynamic>{
        'id':           doc.id,
        'monto':        (data['valor'] as num?)?.toDouble() ?? 0.0,
        'fecha':        data['fecha'] ?? '',
        'descripcion':  data['comentario'] ?? '',
        'id_categoria': data['idCategoria'] ?? '',
        'categoria':    data['categoriaDescripcion'] ?? '',
        'id_tipo':      (data['categoriaTipo'] as num?)?.toInt() ?? 2,
      };
    }).toList();
  }

  /// Inserta un nuevo movimiento.
  /// [categoriaDescripcion] y [categoriaTipo] se desnormalizan para
  /// evitar JOINs en las consultas de lectura.
  Future<void> insertarMovimiento({
    required String idCategoria,
    required String categoriaDescripcion,
    required int    categoriaTipo,
    required double valor,
    required String fecha,
    required String comentario,
  }) async {
    await _movimientos.add({
      'idCategoria':           idCategoria,
      'categoriaDescripcion':  categoriaDescripcion,
      'categoriaTipo':         categoriaTipo,
      'valor':                 valor,
      'fecha':                 fecha,
      'comentario':            comentario,
      'estado':                1,
      'creadoEn':              FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza un movimiento existente.
  Future<void> actualizarMovimiento({
    required String id,
    required String idCategoria,
    required String categoriaDescripcion,
    required int    categoriaTipo,
    required double valor,
    required String fecha,
    required String comentario,
  }) async {
    await _movimientos.doc(id).update({
      'idCategoria':          idCategoria,
      'categoriaDescripcion': categoriaDescripcion,
      'categoriaTipo':        categoriaTipo,
      'valor':                valor,
      'fecha':                fecha,
      'comentario':           comentario,
    });
  }

  /// Baja lógica de movimiento (estado = 0).
  Future<void> eliminarMovimiento(String id) async {
    await _movimientos.doc(id).update({'estado': 0});
  }

  // ── Presupuesto mensual ─────────────────────────────────────────────────────

  /// Genera el docId para presupuesto mensual: "YYYY-MM".
  String _docIdMes(int anio, int mes) =>
      '$anio-${mes.toString().padLeft(2, '0')}';

  /// Guarda (upsert) el presupuesto total del mes indicado.
  Future<void> guardarPresupuestoMensual({
    required int    anio,
    required int    mes,
    required double valor,
  }) async {
    await _presupuestoMensual.doc(_docIdMes(anio, mes)).set(
      {'anio': anio, 'mes': mes, 'valor': valor},
      SetOptions(merge: true),
    );
  }

  /// Obtiene el presupuesto total del mes. Retorna 0.0 si no existe.
  Future<double> obtenerPresupuestoMensual({
    required int anio,
    required int mes,
  }) async {
    final doc = await _presupuestoMensual.doc(_docIdMes(anio, mes)).get();
    if (!doc.exists) return 0.0;
    return (doc.data()?['valor'] as num?)?.toDouble() ?? 0.0;
  }

  // ── Presupuesto por categoría ───────────────────────────────────────────────

  /// Genera el docId para presupuesto de categoría: "YYYY-MM-{idCategoria}".
  String _docIdPresupuestoCat(int anio, int mes, String idCategoria) =>
      '${_docIdMes(anio, mes)}-$idCategoria';

  /// Guarda (upsert) el presupuesto de una categoría para el mes indicado.
  Future<void> guardarPresupuestoCategoria({
    required int    anio,
    required int    mes,
    required String idCategoria,
    required double valor,
  }) async {
    await _presupuestoCategorias
        .doc(_docIdPresupuestoCat(anio, mes, idCategoria))
        .set(
          {'anio': anio, 'mes': mes, 'idCategoria': idCategoria, 'valor': valor},
          SetOptions(merge: true),
        );
  }

  /// Devuelve todas las categorías de egreso activas con su presupuesto del mes.
  /// Combina en memoria (Dart) el resultado de dos consultas independientes,
  /// reemplazando el LEFT JOIN que SQLite realizaba.
  /// Claves del mapa: 'id_categoria' (String), 'categoria' (String), 'valor' (double).
  Future<List<Map<String, dynamic>>> obtenerPresupuestoCategorias({
    required int anio,
    required int mes,
  }) async {
    // 1. Categorías de egreso activas, ordenadas por nombre
    final catSnap = await _categorias
        .where('estado', isEqualTo: 1)
        .where('idTipo', isEqualTo: 2)
        .orderBy('descripcion')
        .get();

    // 2. Presupuestos del mes (todos los registros existentes para anio+mes)
    final presSnap = await _presupuestoCategorias
        .where('anio', isEqualTo: anio)
        .where('mes', isEqualTo: mes)
        .get();

    // 3. Mapa idCategoria → valor presupuestado
    final mapaPresupuestos = <String, double>{};
    for (final doc in presSnap.docs) {
      final data = doc.data();
      final idCat = data['idCategoria'] as String? ?? '';
      mapaPresupuestos[idCat] = (data['valor'] as num?)?.toDouble() ?? 0.0;
    }

    // 4. Combinar: cada categoría con su presupuesto (COALESCE → 0.0 si no existe)
    return catSnap.docs.map((doc) {
      final data = doc.data();
      return <String, dynamic>{
        'id_categoria': doc.id,
        'categoria':    data['descripcion'] ?? '',
        'valor':        mapaPresupuestos[doc.id] ?? 0.0,
      };
    }).toList();
  }

  // ── Totales y agregados ─────────────────────────────────────────────────────

  /// Suma los gastos de una categoría específica en un mes/año dado.
  /// El filtro por fecha se aplica en Dart porque Firestore no tiene strftime.
  Future<double> obtenerTotalGastosPorCategoria(
    String categoria,
    int    anio,
    int    mes,
  ) async {
    final snap = await _movimientos
        .where('estado', isEqualTo: 1)
        .where('categoriaTipo', isEqualTo: 2)
        .where('categoriaDescripcion', isEqualTo: categoria)
        .get();

    double total = 0.0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final fecha = data['fecha'] as String? ?? '';
      try {
        final d = DateTime.parse(fecha);
        if (d.year == anio && d.month == mes) {
          total += (data['valor'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (_) {}
    }
    return total;
  }

  /// Suma total de todos los gastos activos (tipo Egreso).
  Future<double> obtenerTotalGastos() async {
    final snap = await _movimientos
        .where('estado', isEqualTo: 1)
        .where('categoriaTipo', isEqualTo: 2)
        .get();

    double total = 0.0;
    for (final doc in snap.docs) {
      final data = doc.data();
      total += (data['valor'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }
}
