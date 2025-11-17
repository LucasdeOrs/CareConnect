// lib/screens/profile/widgets/edit_pix_screen.dart

import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';

class EditPixScreen extends StatefulWidget {
  final CaregiverProfile caregiverProfile;
  final String? currentPixType;
  final String? currentPixKey;

  const EditPixScreen({
    super.key,
    required this.caregiverProfile,
    this.currentPixType,
    this.currentPixKey,
  });

  @override
  State<EditPixScreen> createState() => _EditPixScreenState();
}

class _EditPixScreenState extends State<EditPixScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pixKeyController = TextEditingController();
  String? _selectedKeyType;
  bool _isLoading = false;

  final List<String> _pixKeyTypes = ['CPF', 'E-mail', 'Telefone', 'Aleatória'];

  @override
  void initState() {
    super.initState();
    _selectedKeyType = widget.currentPixType;
    _pixKeyController.text = widget.currentPixKey ?? '';
  }

  @override
  void dispose() {
    _pixKeyController.dispose();
    super.dispose();
  }

  Future<void> _savePixData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedKeyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um tipo de chave.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase
          .from('cuidadores')
          .update({
            'pix_key_type': _selectedKeyType,
            'pix_key': _pixKeyController.text.trim(),
          })
          .eq('id', widget.caregiverProfile.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados PIX atualizados com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Volta para a tela de recebimentos
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados de Recebimento'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Informe seus dados de PIX para receber os pagamentos dos serviços.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedKeyType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Chave PIX',
                border: OutlineInputBorder(),
              ),
              items: _pixKeyTypes.map((String type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedKeyType = newValue;
                });
              },
              validator: (value) => value == null ? 'Selecione um tipo' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pixKeyController,
              decoration: const InputDecoration(
                labelText: 'Chave PIX',
                hintText: 'Digite sua chave...',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Insira sua chave PIX' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _savePixData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Salvar Dados'),
            ),
          ],
        ),
      ),
    );
  }
}
