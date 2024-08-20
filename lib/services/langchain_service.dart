import 'package:langchain/langchain.dart';

abstract class LangchainService {
  Future<void> createPineconeIndex({required String indexName, required int vectorDimension});
  Future<void> updatePineconeIndex({required String indexName, required List<Document> docs});
  Future<String> queryPineconeVectorStore({required String indexName, required String query});
}
