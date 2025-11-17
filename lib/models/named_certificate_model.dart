import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class NamedCertificate {
  final PlatformFile file;
  String name;
  TextEditingController controller;

  NamedCertificate({required this.file, required this.name})
    : controller = TextEditingController(text: name);

  void dispose() {
    controller.dispose();
  }
}
