import 'dart:io';
import 'package:careconnect_app/models/named_certificate_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class StorageService {
  final SupabaseStorageClient _storage = supabase.storage;

  Future<String?> uploadAvatar(String userId, XFile avatarFile) async {
    try {
      final fileExt = avatarFile.name.split('.').last.toLowerCase();
      final filePath = '$userId/profile.$fileExt';
      final fileBytes = await avatarFile.readAsBytes();

      await _storage
          .from('avatars')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: avatarFile.mimeType,
            ),
          );
      return _storage.from('avatars').getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Erro ao enviar avatar: $e');
    }
  }

  Future<List<Map<String, String>>?> uploadCertificates(
    String userId,
    List<NamedCertificate> certificates,
  ) async {
    if (certificates.isEmpty) return null;

    final List<Map<String, String>> certificateUrls = [];
    const bucketName = 'certificates';

    try {
      for (final NamedCertificate cert in certificates) {
        final safeFileName = cert.controller.text.trim().replaceAll(
          RegExp(r'[^a-zA-Z0-9.-]'),
          '_',
        );
        final certPath =
            '$userId/certificates/${safeFileName}_${cert.file.name}';

        if (kIsWeb) {
          if (cert.file.bytes == null) continue;
          await _storage
              .from(bucketName)
              .uploadBinary(
                certPath,
                cert.file.bytes!,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              );
        } else {
          if (cert.file.path == null) continue;
          await _storage
              .from(bucketName)
              .upload(
                certPath,
                File(cert.file.path!),
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              );
        }

        final publicUrl = _storage.from(bucketName).getPublicUrl(certPath);
        certificateUrls.add({
          'name': cert.controller.text.trim(),
          'url': publicUrl,
        });
      }
      return certificateUrls;
    } catch (e) {
      throw Exception('Erro ao enviar certificados: $e');
    }
  }
}
