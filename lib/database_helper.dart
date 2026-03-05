import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('card_organizer.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return openDatabase(
      path,
      version: 1,
      // enable foreign key constraints for this connection
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Folders table
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_name TEXT NOT NULL UNIQUE,
        timestamp TEXT NOT NULL
      )
    ''');

    // Cards table (folder_id is NOT NULL; cascade delete enabled)
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT NOT NULL,
        folder_id INTEGER NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES folders(id)
          ON DELETE CASCADE
          ON UPDATE CASCADE
      )
    ''');

    // Helpful index for queries like: SELECT * FROM cards WHERE folder_id = ?
    await db.execute('CREATE INDEX idx_cards_folder_id ON cards(folder_id)');

    await _prepopulateFolders(db);
    await _prepopulateCards(db);
  }

  Future<void> _prepopulateFolders(Database db) async {
    final folders = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
    final now = DateTime.now().toIso8601String();

    for (final name in folders) {
      await db.insert('folders', {
        'folder_name': name,
        'timestamp': now,
      });
    }
  }

  /// asset naming example: 2C.png for 2 of Clubs.
  /// We'll use: A,2..10,J,Q,K + suit letter: C,D,H,S
  /// Example outputs: Ace of Spades => AS.png
  Future<void> _prepopulateCards(Database db) async {
    const suitMap = {
      'Clubs': 'C',
      'Diamonds': 'D',
      'Hearts': 'H',
      'Spades': 'S',
    };

    const ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

    // Because we inserted folders in order, their ids will be 1..4 in that order.
    // If you want to be extra safe, you can query IDs by name instead.
    final folderNames = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];

    for (int i = 0; i < folderNames.length; i++) {
      final folderName = folderNames[i];
      final suitLetter = suitMap[folderName]!;
      final folderId = i + 1;

      for (final rank in ranks) {
        await db.insert('cards', {
          'card_name': rank, // store rank token (A,2..10,J,Q,K)
          'suit': folderName, // store full suit name
          'image_url': 'assets/images/${rank}${suitLetter}.png',
          'folder_id': folderId,
        });
      }
    }
  }

  // helpers to prove cascade works

  Future<int> deleteFolder(int folderId) async {
    final db = await database;
    return db.delete('folders', where: 'id = ?', whereArgs: [folderId]);
    // cards will be deleted automatically because of ON DELETE CASCADE
  }

  Future<int> countCardsInFolder(int folderId) async {
    final db = await database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cards WHERE folder_id = ?', [folderId]),
    );
    return result ?? 0;
  }
}