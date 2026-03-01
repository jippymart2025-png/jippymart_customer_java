import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cart.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5, // ✅ Bumped version to add merchant_price
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE cart_products ADD COLUMN vendorName TEXT',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE cart_products ADD COLUMN promo_id TEXT NULL',
          );
        }
        if (oldVersion < 4) {
          // ✅ Change vendorName to nullable
          await db.execute(
            'ALTER TABLE cart_products RENAME TO cart_products_old',
          );

          await _createDB(db, newVersion);

          await db.execute('''
            INSERT INTO cart_products (id, category_id, name, photo, price, discountPrice, vendorID, vendorName, quantity, extras_price, extras, variant_info, promo_id)
            SELECT id, category_id, name, photo, price, discountPrice, vendorID, vendorName, quantity, extras_price, extras, variant_info, promo_id
            FROM cart_products_old
          ''');

          await db.execute('DROP TABLE cart_products_old');
        }

        // 🔁 v5 migration: add merchant_price column to existing table
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE cart_products ADD COLUMN merchant_price TEXT',
          );
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    // ✅ Changed schema: vendorName is now nullable
    const textType = 'TEXT'; // previously 'TEXT NOT NULL'
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
    CREATE TABLE cart_products (
      id $textType,
      category_id $textType,
      name $textType,
      photo $textType,
      price $textType,
      discountPrice $textType,
      merchant_price $textType,
      vendorID $textType,
      vendorName $textType,       -- ✅ now nullable
      quantity $intType,
      extras_price $textType,
      extras $textType,
      variant_info $textType NULL,
      promo_id TEXT NULL
    )
    ''');

    if (kDebugMode) {
      print('✅ Table cart_products created (version $version)');
    }
  }

  //changes
  Future<void> insertCartProduct(CartProductModel product) async {
    final db = await instance.database;
    final data = product.toJson()
      ..['variant_info'] = jsonEncode(product.variantInfo)
      ..['extras'] = jsonEncode(product.extras)
      ..['vendorName'] = product.vendorName ?? 'Unknown Vendor';
    if (kDebugMode) log('🛒 insertCartProduct -> $data');
    await db.insert(
      'cart_products',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CartProductModel>> fetchCartProducts() async {
    final db = await instance.database;
    final maps = await db.query('cart_products');
    if (kDebugMode) {
      print('DEBUG: DatabaseHelper - Found ${maps.length} cart products');
    }
    return List.generate(maps.length, (i) {
      return CartProductModel.fromJson(maps[i]);
    });
  }

  Future<void> updateCartProduct(CartProductModel product) async {
    final db = await instance.database;
    final data = product.toJson()
      ..['variant_info'] = jsonEncode(product.variantInfo)
      ..['extras'] = jsonEncode(product.extras)
      ..['vendorName'] = product.vendorName ?? 'Unknown Vendor';
    if (kDebugMode) log('🛠 updateCartProduct -> $data');
    await db.update(
      'cart_products',
      data,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteCartProduct(String id) async {
    final db = await instance.database;
    await db.delete('cart_products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateCartProductQuantity(String id, String quantity) async {
    final db = await instance.database;
    await db.update(
      'cart_products',
      {'quantity': int.tryParse(quantity) ?? 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllCartProducts() async {
    final db = await instance.database;
    await db.delete('cart_products');
    if (kDebugMode) print('🗑 All cart products deleted');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
