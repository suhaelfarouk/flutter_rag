import 'dart:developer';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kuery_app/services/langchain_service.dart';
import 'package:kuery_app/services/pinecone_control_plane_service.dart';
import 'package:kuery_app/services/pinecone_data_plane_service.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_pinecone/langchain_pinecone.dart';
import 'package:pinecone/pinecone.dart';

import '../core/config.dart';

final langchainServiceProvider = Provider<LangchainService>((ref) {
  final pineConeApiKey = dotenv.env['PINECONE_API_KEY']!;
  final environment = dotenv.env['PINECONE_ENVIRONMENT']!;
  final openAIApiKey = dotenv.env['OPENAI_API_KEY']!;

  final pineconeClient = PineconeClient(
    apiKey: pineConeApiKey,
    baseUrl: 'https://api.pinecone.io',
  );

  final embeddings = OpenAIEmbeddings(
    apiKey: openAIApiKey,
  );

  final langchainPinecone = Pinecone(
    apiKey: pineConeApiKey,
    indexName: ServiceConfig.indexName,
    embeddings: embeddings,
    environment: environment,
  );

  final openAI = OpenAI(
    apiKey: openAIApiKey,
  );

  return LangchainImplement(
    client: pineconeClient,
    langchainPinecone: langchainPinecone,
    embeddings: embeddings,
    openAI: openAI,
  );
});

class LangchainImplement implements LangchainService {
  final PineconeClient client;
  final Pinecone langchainPinecone;
  final OpenAIEmbeddings embeddings;
  final OpenAI openAI;

  LangchainImplement({
    required this.client,
    required this.langchainPinecone,
    required this.embeddings,
    required this.openAI,
  });

  @override
  Future<void> createPineconeIndex({required String indexName, required int vectorDimension}) async {
    print("Checking $indexName");

    try {
      final indexes = await PineconeControlPlaneService().getIndexes();
      // await client.listIndexes(
      //   environment: dotenv.env['PINECONE_ENVIRONMENT']!,
      // );
      if (!indexes.contains(indexName)) {
        print("Creating $indexName ...");
        await PineconeControlPlaneService().createIndex(
          indexName: indexName,
          vectorDimension: vectorDimension,
          searchMetric: 'cosine',
          cloud: 'aws',
          region: 'us-east-1',
        );
        // await client.createIndex(
        //   environment: dotenv.env['PINECONE_ENVIRONMENT']!,
        //   request: CreateIndexRequest(
        //     name: indexName,
        //     dimension: vectorDimension,
        //     metric: SearchMetric.cosine,
        //   ),
        // );
        print('Creating index.... please wait for it to finish initializing.');
        // await Future.delayed(const Duration(seconds: 5));
      } else {
        print("$indexName already exists");
      }
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  Future<String> queryPineconeVectorStore({required String indexName, required String query}) async {
    try {
      // final index = await client.describeIndex(indexName: indexName, environment: dotenv.env['PINECONE_ENVIRONMENT']!);
      final queryEmbedding = await embeddings.embedQuery(query);
      final result = await PineconeDataPlaneService().queryVector(topK: 10, vector: queryEmbedding);
      // PineconeClient(
      // apiKey: dotenv.env['PINECONE_API_KEY']!, baseUrl: 'https://${index.name}-${index.projectId}.svc.${index.environment}.pinecone.io')
      // client.queryVectors(
      //   indexName: index.name,
      //   projectId: index.projectId,
      //   environment: index.environment,
      //   request: QueryRequest(
      //     topK: 10,
      //     vector: queryEmbedding,
      //     includeMetadata: true,
      //     includeValues: true,
      //   ),
      // );
      if (result['matches'].isNotEmpty) {
        final concatPageContent = result['matches'].map((e) {
          if (e['metadata'] == null) return '';
          // check if the metadata has a 'pageContent' key
          if (e['metadata']!.containsKey('pageContent')) {
            return e['metadata']!['pageContent'];
          } else {
            return '';
          }
        }).join(' ');

        final docChain = StuffDocumentsQAChain(llm: openAI);
        final response = await docChain.call({
          'input_documents': [Document(pageContent: concatPageContent)],
          'question': query,
        });

        print(response);

        return response['output'];
      } else {
        return 'No results found';
      }
    } catch (e) {
      print(e);
      throw Exception('Error querying pinecone index');
    }
  }

  @override
  Future<void> updatePineconeIndex({required String indexName, required List<Document> docs}) async {
    try {
      // print("Retrieving Pinecone index...");
      // final index = await client.describeIndex(indexName: indexName, environment: dotenv.env['PINECONE_ENVIRONMENT']!);
      // print('Pinecone index retrieved: ${index.name}');

      for (final doc in docs) {
        print('Processing document: ${doc.metadata['source']}');
        final txtPath = doc.metadata['source'] as String;
        final text = doc.pageContent;
        const textSplitter = RecursiveCharacterTextSplitter(chunkSize: 1000);
        final chunks = textSplitter.createDocuments([text]);
        print('Text split into ${chunks.length} chunks');
        print('Calling OpenAI\'s Embedding endpoint documents with ${chunks.length} text chunks ...');

        final chunksMap = chunks
            .map(
              (e) => Document(
                id: e.id,
                pageContent: e.pageContent.replaceAll(RegExp('/\n/g'), "  "),
                metadata: doc.metadata,
              ),
            )
            .toList();

        final embeddingArrays = await embeddings.embedDocuments(chunksMap);
        print('Finished embedding documents');
        print('Creating ${chunks.length} vectors array with id, values, and metadata...');

        const batchSize = 100;
        for (int i = 0; i < chunks.length; i++) {
          final chunk = chunks[i];
          final embeddingArray = embeddingArrays[i];

          List<Vector> chunkVectors = [];

          final chunkVector = Vector(id: '${txtPath}_$i', values: embeddingArray, metadata: {
            ...chunk.metadata,
            // 'loc': jsonEncode(chunk.metadata['loc']),
            'pageContent': chunk.pageContent,
            'txtPath': txtPath,
          });

          chunkVectors.add(chunkVector);

          if (chunkVectors.length == batchSize || i == chunks.length - 1) {
            await
                // PineconeClient(
                //         apiKey: dotenv.env['PINECONE_API_KEY']!, baseUrl: 'https://${index.name}-${index.projectId}.svc.${index.environment}.pinecone.io')

                PineconeDataPlaneService().upsertVector(vectors: chunkVectors);
            //   client.upsertVectors(
            // indexName: index.name,
            // environment: index.environment,
            // projectId: index.projectId,
            // request: UpsertRequest(vectors: chunkVectors),
            // );

            print('Pinecone index updated with ${chunkVectors.length} vectors');

            chunkVectors = [];
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }
}
