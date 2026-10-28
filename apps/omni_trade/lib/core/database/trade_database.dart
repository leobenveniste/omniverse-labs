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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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
        notes TEXT,
        entry_screenshot_path TEXT,
        exit_screenshot_path TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_trades_status ON trades(status)');
    await db.execute('CREATE INDEX idx_trades_entry_date ON trades(entry_date)');
    await db.execute('CREATE INDEX idx_trades_asset_class ON trades(asset_class)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE trades ADD COLUMN entry_screenshot_path TEXT');
      await db.execute('ALTER TABLE trades ADD COLUMN exit_screenshot_path TEXT');
    }
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

  Future<int> clearAll() async {
    final db = await database;
    return await db.delete('trades');
  }

  Future<List<TradeOperation>> getAllTrades() async {
    final db = await database;
    final maps = await db.query(
      'trades',
      orderBy: 'entry_date DESC',
    );
    return maps.map((m) => TradeOperation.fromMap(m)).toList();
  }

  Future<TradeOperation?> getTradeById(String id) async {
    final db = await database;
    final maps = await db.query(
      'trades',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return TradeOperation.fromMap(maps.first);
    }
    return null;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
