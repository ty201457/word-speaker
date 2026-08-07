import 'dart:convert';
import 'dart:io';

import '../models/dictionary_entry.dart';

class DictionaryException implements Exception {
  const DictionaryException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DictionaryService {
  DictionaryService({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  Future<DictionaryEntry> lookup(String input) async {
    final word = input.trim().toLowerCase();
    if (word.isEmpty) {
      throw const DictionaryException('請先輸入英文單字');
    }
    if (!RegExp(r"^[a-z][a-z'-]*$").hasMatch(word)) {
      throw const DictionaryException('目前只支援單一英文單字');
    }

    try {
      final uri = Uri.https(
        'api.dictionaryapi.dev',
        '/api/v2/entries/en/$word',
      );
      final request = await _client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(const Duration(seconds: 10));
      final body = await utf8.decoder.bind(response).join();

      if (response.statusCode == HttpStatus.notFound) {
        throw const DictionaryException('查不到這個單字，請檢查拼字');
      }
      if (response.statusCode != HttpStatus.ok) {
        throw const DictionaryException('字典服務暫時無法使用');
      }

      final decoded = jsonDecode(body);
      if (decoded is! List<dynamic>) {
        throw const DictionaryException('字典資料格式不正確');
      }
      return DictionaryEntry.fromApi(decoded);
    } on DictionaryException {
      rethrow;
    } on SocketException {
      throw const DictionaryException('無法連線，請確認網路狀態');
    } on FormatException {
      throw const DictionaryException('查不到這個單字，請檢查拼字');
    } catch (_) {
      throw const DictionaryException('查詢失敗，請稍後再試');
    }
  }

  void close() => _client.close(force: true);
}
