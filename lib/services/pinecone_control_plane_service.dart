import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PineconeControlPlaneService {
  final Dio _client;
  PineconeControlPlaneService()
      : _client = Dio(BaseOptions(
          baseUrl: 'https://api.pinecone.io',
          headers: {
            'Api-Key': dotenv.env['PINECONE_API_KEY']!,
            'X-Pinecone-API-Version': '2024-07',
          },
        ));

  Future<List<String>> getIndexes() async {
    try {
      final response = await _client.get('/indexes');
      final List<dynamic> indexes = response.data['indexes'];
      final List<String> indexNames = indexes.map((index) => index['name'] as String).toList();
      return indexNames;
    } catch (e) {
      print('Error fetching indexes: $e');
      return [];
    }
  }

  Future<void> createIndex({
    required String indexName,
    required int vectorDimension,
    required String searchMetric,
    required String cloud,
    required String region,
  }) async {
    try {
      final response = await _client.post('/indexes', data: {
        'name': indexName,
        'dimension': vectorDimension,
        'metric': searchMetric,
        'spec': {
          'serverless': {'cloud': cloud, 'region': region}
        },
        'deletion_protection': false,
      });
      print('Index created: ${response.data}');
    } catch (e) {
      print('Error creating index: $e');
    }
  }
}
