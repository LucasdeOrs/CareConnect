import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImageUploadWidget extends StatelessWidget {
  final ValueNotifier<XFile?> profileImageNotifier;
  final ImagePicker imagePicker;
  final String? initialImageUrl;

  const ImageUploadWidget({
    super.key,
    required this.profileImageNotifier,
    required this.imagePicker,
    this.initialImageUrl,
  });

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (pickedImage != null) {
        profileImageNotifier.value = pickedImage;
      }
    } catch (e) {
      debugPrint("Erro ao selecionar imagem: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Foto de Perfil', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ValueListenableBuilder<XFile?>(
              valueListenable: profileImageNotifier,
              builder: (context, newImage, child) {
                ImageProvider? backgroundImage;

                if (newImage != null) {
                  if (kIsWeb) {
                    backgroundImage = NetworkImage(newImage.path);
                  } else {
                    backgroundImage = FileImage(File(newImage.path));
                  }
                } else if (initialImageUrl != null &&
                    initialImageUrl!.isNotEmpty) {
                  backgroundImage = NetworkImage(initialImageUrl!);
                }

                return CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: backgroundImage,
                  child: (backgroundImage == null)
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file),
                label: const Text('Selecionar foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
