import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:spendscontrol/models/mtd.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'my_database.db');

    await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {

        await db.execute('''
          CREATE TABLE USUARIOS 
          (
            ID INTEGER PRIMARY KEY,
            NOMBRE TEXT NOT NULL,
            CODIGO TEXT NOT NULL,
            CORREO TEXT NOT NULL,
            CLAVE TEXT NOT NULL
          )
        ''');

        // await db.execute('''
        //   INSERT INTO USUARIOS
        //   VALUES
        //   (1, 'ADMINISTRADOR', 'ADMIN', '@')
        // ''');

        await db.execute('''
          CREATE TABLE MOVIMIENTOS_TIPOS
          (
            ID INTEGER PRIMARY KEY,
            DESCRIPCION TEXT NOT NULL
          )
        ''');

        await db.execute('''
          INSERT INTO MOVIMIENTOS_TIPOS
          VALUES
          (1, 'INGRESO'), (2, 'EGRESO')
        ''');

        await db.execute('''
          CREATE TABLE MOVIMIENTOS_CATEGORIAS
          (
            ID INTEGER PRIMARY KEY,
            DESCRIPCION TEXT NOT NULL,
            ID_TIPO INT,
            ESTADO INT DEFAULT 1
          )
        ''');

	      await db.execute('''
          INSERT INTO MOVIMIENTOS_CATEGORIAS 
          (ID, DESCRIPCION, ID_TIPO)
          VALUES
            (1, 'Comida', 2),
            (2, 'Transporte', 2),
            (3, 'Salario', 1)
        ''');

        await db.execute('''
          CREATE TABLE MOVIMIENTOS_X_USUARIO
          (
            ID INTEGER PRIMARY KEY,
            ID_CATEGORIA INT,
            FECHA DATE,
            COMENTARIO TEXT,
            VALOR NUMERC,
            ESTADO INT
          )
        ''');

        await db.execute('''
          CREATE TABLE PARAMETROS_GASTOS_MENSUALES
          (
            ID INTEGER PRIMARY KEY,
            ANIO INT,
            MES INT,
            VALOR NUMERC
          )
        ''');

        await db.execute('''
          CREATE TABLE PRESUPUESTO_CATEGORIAS (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            anio INTEGER,
            mes INTEGER,
            ID_CATEGORIA INT,
            valor REAL
          )
        ''');
      },

	// onOpen: (db) async {
  //       await db.execute('''
  //         CREATE TABLE IF NOT EXISTS MOVIMIENTOS_CATEGORIAS
  //         (
  //           ID INTEGER PRIMARY KEY,
  //           DESCRIPCION TEXT NOT NULL,
  //           ID_TIPO INT
  //         )
  //       ''');

  //       final count = Sqflite.firstIntValue(
  //         await db.rawQuery('SELECT COUNT(*) FROM MOVIMIENTOS_CATEGORIAS'),
  //       ) ?? 0;

  //       if (count == 0) {
  //         await db.execute('''
  //           INSERT OR IGNORE INTO MOVIMIENTOS_CATEGORIAS (ID, DESCRIPCION)
  //           VALUES
  //             (1, 'Comida'),
  //             (2, 'Transporte'),
  //             (3, 'Salario'),
  //             (4, 'Servicios'),
  //             (5, 'Entretenimiento'),
  //             (6, 'Educación'),
  //             (7, 'Salud'),
  //             (8, 'Compras'),
  //             (9, 'Otros')
  //         ''');
  //       }
  //     },
    );
  }

  Future<List<String>> getCategorias() async {
    final db = await database;
    final rows = await db.query(
      'MOVIMIENTOS_CATEGORIAS',
      where: 'ESTADO = 1',
      orderBy: 'DESCRIPCION ASC',
    );
    return rows.map((row) => row['DESCRIPCION'] as String).toList();
  }

  Future<List<String>> getCategoriasEgresos() async {
    final db = await database;
    final rows = await db.query(
      'MOVIMIENTOS_CATEGORIAS',
      where: 'ESTADO = 1 AND ID_TIPO = 2',
      orderBy: 'DESCRIPCION ASC',
    );
    return rows.map((row) => row['DESCRIPCION'] as String).toList();
  }

  Future<bool> mtdDBLocalBuscarSiHayUsuariosHoy() async {
    final db = await database;

    final result = await db.query(
      'USUARIOS',
    );
    
    if (result.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }
  
  // Future<List<String>> getCategorias() async {
  //   final db = await database;
  //   final rows = await db.query(
  //     'MOVIMIENTOS_CATEGORIAS',
  //     orderBy: 'descripcion ASC',
  //   );

  //   return rows.map((row) => row['descripcion'] as String).toList();
  // }

  Future<int> mtdDBLocalInsertUsuario(
    String vrNombre,
    String vrCodigo,
    String vrCorreo,
    String vrClave,
  ) async {
    final db = await database;
    // NOTA: Este método ya no es utilizado por autenticación (migrado a Firebase Auth).
    // Se conserva para compatibilidad mientras SQLite siga activo en otros módulos.
    return await db.insert(
      'USUARIOS',
      {
        'NOMBRE': vrNombre.trim(),
        'CODIGO': vrCodigo.trim(),
        'CORREO': vrCorreo.trim(),
        'CLAVE': vrClave.trim(),
      },
    );
  }

  Future<bool> mtdDBLocalExisteCorreoUsuario(String vrCorreo) async {
    final db = await database;

    final result = await db.query(
      'USUARIOS',
      where: 'TRIM(UPPER(CORREO)) = ?',
      whereArgs: [vrCorreo.trim().toUpperCase()],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<int> mtdDBLocalActualizarClavePorCorreo(
    String vrCorreo,
    String vrClave,
  ) async {
    final db = await database;
    // NOTA: Este método ya no es utilizado por autenticación (migrado a Firebase Auth).
    // Se conserva para compatibilidad mientras SQLite siga activo en otros módulos.
    return await db.update(
      'USUARIOS',
      {
        'CLAVE': vrClave.trim(),
      },
      where: 'TRIM(UPPER(CORREO)) = ?',
      whereArgs: [vrCorreo.trim().toUpperCase()],
    );
  }

  Future<Map<String, dynamic>> mtdDBLocalLoginRecord(
    String vrUsuario, String vrClave) async {
    // NOTA: Este método ya no es utilizado por autenticación (migrado a Firebase Auth).
    // Se conserva para compatibilidad mientras SQLite siga activo en otros módulos.
    final db = await database;

    final result = await db.query(
      'USUARIOS',
      where: 'TRIM(CODIGO) = ? AND TRIM(CLAVE) = ?',
      whereArgs: [vrUsuario.trim(), vrClave.trim()],
      limit: 1,
    );

    if (result.isNotEmpty) {

      final row = result.first;

      return {
          "id": row["ID"] ?? 0,
          "nombre": row["NOMBRE"] ?? ""
      };

    } else {

      return {
          "id": 0,
          "nombre": ""
      };

    }
  }

  Future<List<Map<String, dynamic>>> obtenerCategoriasCompletas() async {
    final db = await database;

    return await db.query(
      'MOVIMIENTOS_CATEGORIAS',
      where: ' ESTADO = 1 ',
      orderBy: 'DESCRIPCION ASC',
    );
  }

  Future<List<Map<String, dynamic>>> obtenerMovimientosCompletos() async {
    final db = await database;

    return await db.rawQuery('''
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
  }

  Future<int> insertarMovimiento({
    required int idCategoria,
    required double valor,
    required String fecha,
    required String comentario,
  }) async {
    final db = await database;

    return await db.insert(
      'MOVIMIENTOS_X_USUARIO',
      {
        'ID_CATEGORIA': idCategoria,
        'VALOR': valor,
        'FECHA': fecha,
        'COMENTARIO': comentario,
        'ESTADO': 1,
      },
    );
  }

  Future<int> actualizarMovimiento({
    required int id,
    required int idCategoria,
    required double valor,
    required String fecha,
    required String comentario,
  }) async {
    final db = await database;

    return await db.update(
      'MOVIMIENTOS_X_USUARIO',
      {
        'ID_CATEGORIA': idCategoria,
        'VALOR': valor,
        'FECHA': fecha,
        'COMENTARIO': comentario,
      },
      where: 'ID = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminarMovimiento(int id) async {
    final db = await database;

    return await db.update(
      'MOVIMIENTOS_X_USUARIO',
      {'ESTADO': 0},
      where: 'ID = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertarCategoria(String descripcion, int idTipo) async {
    final db = await database;

    return await db.insert(
      'MOVIMIENTOS_CATEGORIAS',
      {
        'DESCRIPCION': descripcion.trim(),
        'ID_TIPO': idTipo,
      },
    );
  }

  Future<int> modificarCategoria(int id, String descripcion, int idTipo) async {
    final db = await database;

    return await db.update(
      'MOVIMIENTOS_CATEGORIAS',
      {
        'DESCRIPCION': descripcion.trim(),
        'ID_TIPO': idTipo,
      },
      where: 'ID = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminarCategoriaBD(int id) async {
    final db = await database;

    return await db.update(
      'MOVIMIENTOS_CATEGORIAS',
      {
        'ESTADO': 2,
      },
      where: 'ID = ?',
      whereArgs: [id],
    );
  }

  Future<int> guardarPresupuestoMensual({
    required int anio,
    required int mes,
    required double valor,
  }) async {
    final db = await database;

    final existe = await db.query(
      'PARAMETROS_GASTOS_MENSUALES',
      where: 'anio = ? AND mes = ?',
      whereArgs: [anio, mes],
      limit: 1,
    );

    if (existe.isNotEmpty) {
      return await db.update(
        'PARAMETROS_GASTOS_MENSUALES',
        {'valor': valor},
        where: 'anio = ? AND mes = ?',
        whereArgs: [anio, mes],
      );
    }

    return await db.insert(
      'PARAMETROS_GASTOS_MENSUALES',
      {
        'anio': anio,
        'mes': mes,
        'valor': valor,
      },
    );
  }

  Future<double> obtenerPresupuestoMensual({
    required int anio,
    required int mes,
  }) async {
    final db = await database;

    final result = await db.query(
      'PARAMETROS_GASTOS_MENSUALES',
      where: 'ANIO = ? AND MES = ?',
      whereArgs: [anio, mes],
      limit: 1,
    );

    if (result.isEmpty) return 0.0;

    return double.tryParse(result.first['VALOR'].toString()) ?? 0.0;
  }

  Future<int> guardarPresupuestoCategoria({
    required int anio,
    required int mes,
    required int idCategoria,
    required double valor,
  }) async {
    final db = await database;

    final existe = await db.query(
      'PRESUPUESTO_CATEGORIAS',
      where: 'anio = ? AND mes = ? AND ID_CATEGORIA = ?',
      whereArgs: [anio, mes, idCategoria],
      limit: 1,
    );

    if (existe.isNotEmpty) {
      return await db.update(
        'PRESUPUESTO_CATEGORIAS',
        {'valor': valor},
        where: 'anio = ? AND mes = ? AND ID_CATEGORIA = ?',
        whereArgs: [anio, mes, idCategoria],
      );
    }

    return await db.insert(
      'PRESUPUESTO_CATEGORIAS',
      {
        'anio': anio,
        'mes': mes,
        'ID_CATEGORIA': idCategoria,
        'valor': valor,
      },
    );
  }

  Future<List<Map<String, dynamic>>> obtenerPresupuestoCategorias({
    required int anio,
    required int mes,
  }) async {
    final db = await database;

    return await db.rawQuery(
      '''
      SELECT
        A.ID AS id_categoria,
        A.DESCRIPCION AS categoria,
        COALESCE(B.valor, 0.00) AS valor
      FROM MOVIMIENTOS_CATEGORIAS A
      LEFT JOIN PRESUPUESTO_CATEGORIAS B
        ON B.ID_CATEGORIA = A.ID
        AND B.anio = ?
        AND B.mes = ?
      WHERE A.ESTADO = 1
      AND A.ID_TIPO = 2
      ORDER BY A.DESCRIPCION ASC
      ''',
      [anio, mes],
    );
  }

  Future<double> obtenerTotalGastosPorCategoria(String categoria, int vrAnio, int vrMes) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(A.VALOR), 0.00) as total
      FROM MOVIMIENTOS_X_USUARIO A
      INNER JOIN MOVIMIENTOS_CATEGORIAS B ON A.ID_CATEGORIA = B.ID
      WHERE B.ID_TIPO = 2
      AND A.ESTADO = 1
      AND B.DESCRIPCION = ?
      AND CAST(strftime('%Y', A.FECHA) AS INTEGER) = ?
      AND CAST(strftime('%m', A.FECHA) AS INTEGER) = ?
      ''',
      [categoria, vrAnio, vrMes],
    );

    return double.tryParse(result.first['total'].toString()) ?? 0.0;
  }

  Future<double> obtenerTotalGastos() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT NVL(SUM(VALOR),0.00) as total
      FROM MOVIMIENTOS_X_USUARIO A
      INNER JOIN MOVIMENTOS_CATEGORIAS B ON A.ID_CATEGORIA = B.ID
      WHERE B.ID_TIPO = 2
      AND A.ESTADO = 1
    ''');

    return double.tryParse(result.first['total'].toString()) ?? 0.0;
  }

}

