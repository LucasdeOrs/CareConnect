import 'package:careconnect_app/main.dart';
import 'package:careconnect_app/models/patient_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientService {
  Future<List<PatientModel>> getPatients(String familiarId) async {
    try {
      final data = await supabase
          .from('pacientes')
          .select()
          .eq('familiar_id', familiarId)
          .order('nome', ascending: true);

      return (data as List).map((item) => PatientModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar pacientes: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSimplePatients(
    String familiarId,
  ) async {
    try {
      final data = await supabase
          .from('pacientes')
          .select('id, nome')
          .eq('familiar_id', familiarId)
          .order('nome', ascending: true);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erro ao buscar pacientes: $e');
    }
  }

  Future<void> createPatient(Map<String, dynamic> data) async {
    try {
      await supabase.from('pacientes').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao criar paciente: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao criar paciente: $e');
    }
  }

  Future<void> updatePatient(
    String patientId,
    Map<String, dynamic> data,
  ) async {
    try {
      await supabase.from('pacientes').update(data).eq('id', patientId);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao atualizar paciente: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao atualizar paciente: $e');
    }
  }

  Future<void> deletePatient(String patientId) async {
    try {
      await supabase.from('pacientes').delete().eq('id', patientId);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao excluir paciente: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao excluir paciente: $e');
    }
  }
}
