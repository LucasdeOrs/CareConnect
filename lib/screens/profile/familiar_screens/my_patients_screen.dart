import 'package:careconnect_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyPatientsScreen extends StatefulWidget {
  const MyPatientsScreen({super.key});

  @override
  State<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends State<MyPatientsScreen> {
  late Future<List<Map<String, dynamic>>> _patientsFuture;

  @override
  void initState() {
    super.initState();
    _patientsFuture = _fetchPatients();
  }

  Future<List<Map<String, dynamic>>> _fetchPatients() async {
    final userId = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('pacientes')
        .select()
        .eq('familiar_id', userId)
        .order('nome', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  void _refreshList() {
    setState(() {
      _patientsFuture = _fetchPatients();
    });
  }

  Future<void> _deletePatient(String patientId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Paciente'),
        content: const Text('Tem certeza que deseja excluir este paciente?'),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('pacientes').delete().eq('id', patientId);

        _refreshList();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paciente removido com sucesso.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showPatientForm({Map<String, dynamic>? patient}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _PatientFormDialog(patient: patient),
    );

    if (result == true) {
      _refreshList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pacientes'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPatientForm(),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _patientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final patients = snapshot.data ?? [];

          if (patients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum paciente cadastrado.\nAdicione quem receberá os cuidados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade50,
                    child: Text(
                      patient['nome'][0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.indigo.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    patient['nome'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${patient['idade'] ?? '?'} anos • ${patient['condicoes'] ?? 'Nenhuma condição informada'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showPatientForm(patient: patient);
                      } else if (value == 'delete') {
                        _deletePatient(patient['id']);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20),
                            SizedBox(width: 8),
                            Text('Excluir'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PatientFormDialog extends StatefulWidget {
  final Map<String, dynamic>? patient;

  const _PatientFormDialog({this.patient});

  @override
  State<_PatientFormDialog> createState() => _PatientFormDialogState();
}

class _PatientFormDialogState extends State<_PatientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _nameController.text = widget.patient!['nome'];
      _ageController.text = widget.patient!['idade']?.toString() ?? '';
      _conditionsController.text = widget.patient!['condicoes'] ?? '';
      _notesController.text = widget.patient!['observacoes'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _conditionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userId = supabase.auth.currentUser!.id;
    final data = {
      'familiar_id': userId,
      'nome': _nameController.text.trim(),
      'idade': int.tryParse(_ageController.text.trim()),
      'condicoes': _conditionsController.text.trim(),
      'observacoes': _notesController.text.trim(),
    };

    try {
      if (widget.patient == null) {
        await supabase.from('pacientes').insert(data);
      } else {
        await supabase
            .from('pacientes')
            .update(data)
            .eq('id', widget.patient!['id']);
      }

      if (mounted) {
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.patient == null
                  ? 'Paciente adicionado!'
                  : 'Paciente atualizado!',
            ),
            backgroundColor: Colors.green,
          ),
        );
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.patient == null ? 'Adicionar Paciente' : 'Editar Paciente',
      ),
      backgroundColor: Colors.white,
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo*',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Obrigatório'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Idade',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _conditionsController,
                decoration: const InputDecoration(
                  labelText: 'Condições / Diagnósticos',
                  hintText: 'Ex: Alzheimer, Diabetes, Hipertensão',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações / Rotina',
                  hintText: 'Ex: Toma remédio às 8h, gosta de caminhar...',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Retorna null (cancelado)
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _savePatient,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Salvar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
