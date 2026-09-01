import 'package:menu_listo/core/database/app_database.dart';
import '../models/shopping_item_model.dart';

class ShoppingRepository {
  final AppDatabase _db;

  ShoppingRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  Future<List<ShoppingItem>> getShoppingItems() {
    return _db.getAllShoppingItems();
  }

  Future<void> saveItem(ShoppingItem item) {
    return _db.insertShoppingItem(item);
  }

  Future<void> saveBatchItems(List<ShoppingItem> items) {
    return _db.insertBatchShoppingItems(items);
  }

  Future<void> updateItem(ShoppingItem item) {
    return _db.updateShoppingItem(item);
  }

  Future<void> deleteItem(String id) {
    return _db.deleteShoppingItem(id);
  }

  Future<void> clearCompleted() {
    return _db.clearCompletedShoppingItems();
  }

  Future<void> clearAll() {
    return _db.clearAllShoppingItems();
  }
}
