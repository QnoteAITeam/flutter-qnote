import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OpenAIApi {
  final String? baseUrl;
  final FlutterSecureStorage _storage;

  static OpenAIApi? _instance;

  OpenAIApi._internal(this.baseUrl, this._storage);

  static OpenAIApi get instance {
    if (_instance != null) return _instance!;

    _instance = OpenAIApi._internal(
      dotenv.env['API_URL'],
      FlutterSecureStorage(),
    );

    return _instance!;
  }
}
