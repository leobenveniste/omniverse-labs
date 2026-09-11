import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/trade_operation.dart';

class TradeDatabase {
  static final TradeDatabase instance = TradeDatabase._init();
  static Database? _database;

  TradeDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('omnitrade.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trades (
        id TEXT PRIMARY KEY,
        symbol TEXT NOT NULL,
        asset_class TEXT NOT NULL,
        direction TEXT NOT NULL,
        status TEXT NOT NULL,
        entry_price REAL NOT NULL,
        exit_price REAL,
        quantity REAL NOT NULL,
        multiplier REAL NOT NULL DEFAULT 1.0,
        fees REAL NOT NULL DEFAULT 0.0,
        stop_loss REAL,
        take_profit REAL,
        entry_date TEXT NOT NULL,
        exit_date TEXT,
        strategy_tag TEXT,
        emotion_tag TEXT,
        notes TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_trades_status ON trades(status)');
    await db.execute('CREATE INDEX idx_trades_entry_date ON trades(entry_date)');
    await db.execute('CREATE INDEX idx_trades_asset_class ON trades(asset_class)');
  }

  Future<int> insertTrade(TradeOperation trade) async {
    final db = await database;
    return await db.insert(
      'trades',
      trade.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTrade(TradeOperation trade) async {
    final db = await database;
    return await db.update(
      'trades',
      trade.toMap(),
      where: 'id = ?',
      whereArgs: [trade.id],
    );
  }

  Future<int> deleteTrade(String id) async {
    final db = await database;
    return await db.delete(
      'trades',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TradeOperation>> getAllTrades() async {
    final db = await database;
    final maps = await db.query(
      'trades',
      orderBy: 'entry_date DESC',
    );
    return maps.map((e) => TradeOperation.fromMap(e)).toList();
  }

  Future<int> getTradeCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM trades');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('trades');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
