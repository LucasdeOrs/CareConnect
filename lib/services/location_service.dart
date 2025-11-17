import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static List<String> _cachedCities = [];
  static bool _isLoadingApi = false;

  static List<String> get citiesCache => _cachedCities;
  static Future<List<String>> getBrazilianCities() async {
    if (_cachedCities.isNotEmpty) {
      return _cachedCities;
    }

    if (_isLoadingApi) {
      await Future.delayed(const Duration(seconds: 2));
      return _cachedCities;
    }

    _isLoadingApi = true;

    try {
      final url = Uri.parse(
        'https://servicodados.ibge.gov.br/api/v1/localidades/municipios?orderBy=nome',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _cachedCities = data.map((item) {
          final String nome = item['nome'];
          final String uf =
              item['regiao-imediata']['regiao-intermediaria']['UF']['sigla'];
          return "$nome, $uf";
        }).toList();

        _isLoadingApi = false;
        return _cachedCities;
      } else {
        throw Exception('Falha ao carregar cidades do IBGE');
      }
    } catch (e) {
      _isLoadingApi = false;
      throw Exception('Erro ao conectar ao serviço de cidades: $e');
    }
  }
}
