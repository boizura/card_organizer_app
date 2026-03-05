import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future get database async {
    if (_database != null) return _database!;
    _database = await _initDB('card_organizer.db');
    return _database!;
  }

  Future _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Create Folders table
    await db.execute('''
      CREATE TABLE folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_name TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // Create Cards table with foreign key
    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT,
        folder_id INTEGER,
        FOREIGN KEY (folder_id) REFERENCES folders (id)
          ON DELETE CASCADE
      )
    ''');

    // Prepopulate folders
    await _prepopulateFolders(db);
    
    // Prepopulate cards
    await _prepopulateCards(db);
  }

  Future _prepopulateFolders(Database db) async {
    final folders = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
    for (int i = 0; i < folders.length; i++) {
      await db.insert('folders', {
        'folder_name': folders[i],
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future _prepopulateCards(Database db) async {
    final suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
    final cards = ['Ace', '2', '3', '4', '5', '6', '7', 
                   '8', '9', '10', 'Jack', 'Queen', 'King'];
    
    for (int folderId = 1; folderId <= suits.length; folderId++) {
      for (var card in cards) {
        await db.insert('cards', {
          'card_name': card,
          'suit': suits[folderId - 1],
          'image_url': 'assets/cards/${suits[folderId - 1].toLowerCase()}_$card.png',
          'folder_id': folderId,
        });
      }
    }
  }
}