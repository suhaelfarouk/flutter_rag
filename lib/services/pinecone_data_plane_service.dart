import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PineconeDataPlaneService {
  final Dio _client;
  PineconeDataPlaneService()
      : _client = Dio(BaseOptions(
          baseUrl: 'https://${dotenv.env['INDEX_HOST']!}',
          headers: {
            'Api-Key': dotenv.env['PINECONE_API_KEY']!,
            'X-Pinecone-API-Version': '2024-07',
          },
        ));

  Future<dynamic> queryVector({required int topK, required List<double> vector}) async {
    final host = dotenv.env['INDEX_HOST']!;
    final Map<String, dynamic> data = {
      'vector': vector,
      'topK': topK,
      'includeValues': true,
      'includeMetadata': true,
    };
    try {
      final response = await _client.post(
        '$host/query',
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: data,
      );
      if (response.statusCode == 200) {
        log('Query successful: ${response.data}');
        return response.data;
      } else {
        print('Query failed with status: ${response.statusCode}');
        return '';
      }
    } catch (e) {
      print('Error querying Pinecone: $e');
      return '';
    }
  }

  Future<String> upsertVector({required List vectors}) async {
    final host = dotenv.env['INDEX_HOST']!;
    final Map<String, dynamic> data = {
      'vectors': vectors,
    };
    try {
      final response = await _client.post(
        '$host/vectors/upsert',
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: data,
      );
      if (response.statusCode == 200) {
        print('Upsert successful: ${response.data}');
        return response.data['id'];
      } else {
        print('Upsert failed with status: ${response.statusCode}');
        return '';
      }
    } catch (e) {
      print('Error upserting vector: $e');
      return '';
    }
  }
}
