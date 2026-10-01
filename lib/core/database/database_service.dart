import 'database_helper.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Future<void> initialize() async {
    await DatabaseHelper.instance.database;
  }
}
