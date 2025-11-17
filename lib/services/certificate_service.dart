import 'dart:typed_data';
import 'package:careconnect_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CertificateService {
  final SupabaseStorageClient _storage = supabase.storage;
  static const String _bucketName = 'certificates';

  static String? _getMimeTypeFromFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return null;
    }
  }

  Future<Map<String, String>> uploadCertificate({
    required String caregiverId,
    required String fileName,
    required Uint8List fileBytes,
    String? mimeType,
  }) async {
    final filePath = '$caregiverId/$_bucketName/$fileName';

    final resolvedMimeType = mimeType ?? _getMimeTypeFromFileName(fileName);

    try {
      await _storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: resolvedMimeType,
            ),
          );

      final publicUrl = _storage.from(_bucketName).getPublicUrl(filePath);

      return {'name': fileName, 'url': publicUrl};
    } on StorageException catch (e) {
      throw Exception('Erro de Storage: ${e.message}');
    } catch (e) {
      throw Exception('Erro ao enviar arquivo: $e');
    }
  }

  Future<void> deleteCertificate({
    required String caregiverId,
    required String filePathInBucket,
    required List<Map<String, String>> currentCertificates,
  }) async {
    try {
      final path = filePathInBucket.split('/$_bucketName/').last;
      await _storage.from(_bucketName).remove([path]);

      final newList = currentCertificates
          .where((c) => c['url'] != filePathInBucket)
          .toList();

      await supabase
          .from('cuidadores')
          .update({'certificado_url': newList})
          .eq('id', caregiverId);
    } on StorageException catch (e) {
      throw Exception('Erro ao deletar arquivo: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Erro ao atualizar banco: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao excluir: $e');
    }
  }

  Future<void> updateCertificateListInDatabase({
    required String caregiverId,
    required List<Map<String, String>> newList,
  }) async {
    try {
      await supabase
          .from('cuidadores')
          .update({'certificado_url': newList})
          .eq('id', caregiverId);
    } catch (e) {
      throw Exception('Erro ao renomear/atualizar a lista: $e');
    }
  }

  String getPublicUrl(String rawPath) {
    return _storage.from('certificates').getPublicUrl(rawPath);
  }
}
