import 'dart:async';
import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:careconnect_app/screens/caregiver_list/caregiver_detail_modal.dart';
import 'package:careconnect_app/services/caregiver_service.dart';
import 'package:careconnect_app/services/location_service.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/cards/caregiver_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final CaregiverService _caregiverService = CaregiverService();

  final _searchController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _cidadeUFController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  final List<CaregiverProfile> _caregivers = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 10;

  // Filtros Básicos
  String _sortOrder = 'rating_desc';
  String _sortLabel = 'Melhores Avaliados';
  bool _onlyHealthPro = false;
  String _selectedDaysKey = 'todos';
  String _daysLabel = 'Todos os Dias';
  String _selectedTimeKey = 'qualquer';
  String _timeLabel = 'Qualquer Horário';
  RangeValues _priceRange = const RangeValues(0, 500);

  // NOVOS FILTROS (Booleanos)
  bool _filterFumante = false; // true = quero NÃO fumante
  bool _filterCnh = false;
  bool _filterCarro = false;
  bool _filterPets = false;
  bool _filterCozinha = false;
  bool _filterLimpeza = false;
  bool _filterDormir = false;

  // ignore: unused_field
  List<String> _todasCidadesComUF = [];
  bool _isLocalLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _carregarCidades();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.9 &&
          !_isLoading &&
          _hasMore) {
        _loadMoreData();
      }
    });
  }

  void applyFilters({
    String? searchText,
    String? timeKey,
    String? sortOrder,
    bool? onlyHealthPro,
    bool? possuiCarro,
    bool? cozinha,
    bool? limpeza,
    bool? dormirLocal,
    bool? gostaAnimais,
  }) {
    setState(() {
      _currentPage = 0;
      _caregivers.clear();
      _hasMore = true;
      _isLoading = true;

      if (searchText != null) {
        _searchController.text = searchText;
      }

      if (onlyHealthPro != null) _onlyHealthPro = onlyHealthPro;

      if (timeKey != null) {
        _selectedTimeKey = timeKey;
        if (timeKey == 'noite') {
          _timeLabel = 'Noite';
        } else if (timeKey == 'qualquer') {
          _timeLabel = 'Qualquer Horário';
        }
      }

      if (sortOrder != null) {
        _sortOrder = sortOrder;
        if (sortOrder == 'rating_desc') _sortLabel = 'Melhores Avaliados';
      }

      if (possuiCarro != null) {
        _clearExtraFilters();
        _filterCarro = possuiCarro;
      }
      if (cozinha != null) {
        _clearExtraFilters();
        _filterCozinha = cozinha;
      }
      if (limpeza != null) {
        _clearExtraFilters();
        _filterLimpeza = limpeza;
      }
      if (dormirLocal != null) {
        _clearExtraFilters();
        _filterDormir = dormirLocal;
      }
      if (gostaAnimais != null) {
        _clearExtraFilters();
        _filterPets = gostaAnimais;
      }
    });

    _fetchCaregivers();
  }

  void _clearExtraFilters() {
    _filterFumante = false;
    _filterCnh = false;
    _filterCarro = false;
    _filterPets = false;
    _filterCozinha = false;
    _filterLimpeza = false;
    _filterDormir = false;
  }

  void _resetPagination() {
    _currentPage = 0;
    _caregivers.clear();
    _hasMore = true;
    _isLoading = true;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _cidadeUFController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _resetPagination();
    });
    await _fetchCaregivers();
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _currentPage++;
    });
    await _fetchCaregivers();
  }

  Future<void> _fetchCaregivers() async {
    try {
      String? availabilityParam;
      if (_selectedDaysKey == 'fim_semana') {
        availabilityParam = 'Finais de Semana';
      } else if (_selectedDaysKey == 'semana') {
        availabilityParam = 'Dias de Semana';
      } else {
        availabilityParam = null;
      }

      final newCaregivers = await _caregiverService.getCaregivers(
        searchTerm: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        state: _stateController.text.trim().isNotEmpty
            ? _stateController.text.trim()
            : null,
        priceRange: _priceRange,
        onlyHealthProfessionals: _onlyHealthPro,
        availability: availabilityParam,
        sortOrder: _sortOrder,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        fumante: _filterFumante ? false : null,
        habilitaCnh: _filterCnh ? true : null,
        possuiCarro: _filterCarro ? true : null,
        gostaAnimais: _filterPets ? true : null,
        cozinha: _filterCozinha ? true : null,
        limpeza: _filterLimpeza ? true : null,
        dormirLocal: _filterDormir ? true : null,
      );

      if (mounted) {
        setState(() {
          if (newCaregivers.length < _pageSize) {
            _hasMore = false;
          }
          _caregivers.addAll(newCaregivers);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Erro ao buscar cuidadores: $e');
      }
    }
  }

  Future<void> _carregarCidades() async {
    if (LocationService.citiesCache.isNotEmpty) {
      setState(() => _todasCidadesComUF = LocationService.citiesCache);
      return;
    }
    if (_isLocalLoading) return;
    if (mounted) setState(() => _isLocalLoading = true);
    try {
      _todasCidadesComUF = await LocationService.getBrazilianCities();
    } catch (e) {
      debugPrint('Erro ao carregar cidades: $e');
    } finally {
      if (mounted) setState(() => _isLocalLoading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _cityController.clear();
      _stateController.clear();
      _cidadeUFController.clear();
      _priceRange = const RangeValues(0, 500);
      _onlyHealthPro = false;
      _selectedDaysKey = 'todos';
      _daysLabel = 'Todos os Dias';
      _selectedTimeKey = 'qualquer';
      _timeLabel = 'Qualquer Horário';
      _sortOrder = 'rating_desc';
      _sortLabel = 'Melhores Avaliados';

      // Limpa extras
      _filterFumante = false;
      _filterCnh = false;
      _filterCarro = false;
      _filterPets = false;
      _filterCozinha = false;
      _filterLimpeza = false;
      _filterDormir = false;
    });
    _loadInitialData();
  }

  void _showDetails(CaregiverProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Scaffold(
        body: SafeArea(
          child: CaregiverDetailModal(
            caregiver: profile,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Ordenar por',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildFilterOptionTile(
              'Melhores Avaliados',
              _sortOrder == 'rating_desc',
              () => _applySort('rating_desc', 'Melhores Avaliados'),
            ),
            _buildFilterOptionTile(
              'Menores Notas',
              _sortOrder == 'rating_asc',
              () => _applySort('rating_asc', 'Menores Notas'),
            ),
            _buildFilterOptionTile(
              'Menor Preço',
              _sortOrder == 'price_asc',
              () => _applySort('price_asc', 'Menor Preço'),
            ),
            _buildFilterOptionTile(
              'Maior Preço',
              _sortOrder == 'price_desc',
              () => _applySort('price_desc', 'Maior Preço'),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  void _applySort(String key, String label) {
    setState(() {
      _sortOrder = key;
      _sortLabel = label;
    });
    Navigator.pop(context);
    _loadInitialData();
  }

  void _showDaysOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Dias da Semana',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildFilterOptionTile(
              'Todos os Dias',
              _selectedDaysKey == 'todos',
              () => _applyDays('todos', 'Todos os Dias'),
            ),
            _buildFilterOptionTile(
              'Dias Úteis',
              _selectedDaysKey == 'semana',
              () => _applyDays('semana', 'Dias Úteis'),
            ),
            _buildFilterOptionTile(
              'Finais de Semana',
              _selectedDaysKey == 'fim_semana',
              () => _applyDays('fim_semana', 'Finais de Semana'),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  void _applyDays(String key, String label) {
    setState(() {
      _selectedDaysKey = key;
      _daysLabel = label;
    });
    Navigator.pop(context);
    _loadInitialData();
  }

  void _showTimeOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Horário Preferencial',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildFilterOptionTile(
              'Qualquer Horário',
              _selectedTimeKey == 'qualquer',
              () => _applyTime('qualquer', 'Qualquer Horário'),
            ),
            _buildFilterOptionTile(
              'Manhã',
              _selectedTimeKey == 'manha',
              () => _applyTime('manha', 'Manhã'),
            ),
            _buildFilterOptionTile(
              'Tarde',
              _selectedTimeKey == 'tarde',
              () => _applyTime('tarde', 'Tarde'),
            ),
            _buildFilterOptionTile(
              'Noite',
              _selectedTimeKey == 'noite',
              () => _applyTime('noite', 'Noite'),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  void _applyTime(String key, String label) {
    setState(() {
      _selectedTimeKey = key;
      _timeLabel = label;
    });
    Navigator.pop(context);
    _loadInitialData();
  }

  // NOVO: Modal para filtros extras (estilo iFood/Airbnb)
  void _showMoreFiltersOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros Avançados',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: [
                        const Text(
                          "Qualificações & Logística",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        _buildSwitchTileModal(
                          "Não Fumante",
                          "Mostrar apenas não fumantes",
                          _filterFumante,
                          (val) => setModalState(() => _filterFumante = val),
                        ),
                        _buildSwitchTileModal(
                          "Possui CNH",
                          "Carteira de Habilitação válida",
                          _filterCnh,
                          (val) => setModalState(() => _filterCnh = val),
                        ),
                        _buildSwitchTileModal(
                          "Carro Próprio",
                          "Possui veículo para transporte",
                          _filterCarro,
                          (val) => setModalState(() => _filterCarro = val),
                        ),
                        const Divider(),
                        const Text(
                          "Tarefas Aceitas",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        _buildSwitchTileModal(
                          "Cozinha",
                          "Prepara refeições para o paciente",
                          _filterCozinha,
                          (val) => setModalState(() => _filterCozinha = val),
                        ),
                        _buildSwitchTileModal(
                          "Limpeza Leve",
                          "Mantém o ambiente do paciente limpo",
                          _filterLimpeza,
                          (val) => setModalState(() => _filterLimpeza = val),
                        ),
                        _buildSwitchTileModal(
                          "Dorme no Local",
                          "Disponível para pernoite/dormir",
                          _filterDormir,
                          (val) => setModalState(() => _filterDormir = val),
                        ),
                        const Divider(),
                        const Text(
                          "Preferências",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        _buildSwitchTileModal(
                          "Gosta de Pets",
                          "Sente-se confortável com animais",
                          _filterPets,
                          (val) => setModalState(() => _filterPets = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Aplica os filtros e recarrega
                        _loadInitialData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Aplicar Filtros"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSwitchTileModal(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildFilterOptionTile(
    String title,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.primary : Colors.black87,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            icon,
            size: 16,
            color: isActive ? AppColors.primary : Colors.grey.shade600,
          ),
        ],
      ),
      onPressed: onTap,
      backgroundColor: isActive
          // ignore: deprecated_member_use
          ? AppColors.primary.withOpacity(0.1)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isActive ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Verifica se tem algum filtro extra ativo para pintar o botão
    bool hasExtraFilters =
        _filterFumante ||
        _filterCnh ||
        _filterCarro ||
        _filterPets ||
        _filterCozinha ||
        _filterLimpeza ||
        _filterDormir;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: const InputDecoration(
                          hintText: 'Nome, cidade, profissão...',
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    tooltip: 'Limpar filtros',
                    onPressed: _clearFilters,
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // CHIP DE FILTROS EXTRAS (NOVO)
                  ActionChip(
                    avatar: hasExtraFilters
                        ? const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            radius: 4,
                          )
                        : const Icon(Icons.tune, size: 16),
                    label: const Text("Filtros"),
                    onPressed: _showMoreFiltersOptions,
                    backgroundColor: hasExtraFilters
                        // ignore: deprecated_member_use
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: hasExtraFilters
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  _buildFilterChip(
                    label: _sortLabel,
                    icon: Icons.keyboard_arrow_down,
                    isActive: _sortOrder != 'rating_desc',
                    onTap: _showSortOptions,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Profissional Saúde'),
                    selected: _onlyHealthPro,
                    onSelected: (val) {
                      setState(() => _onlyHealthPro = val);
                      _loadInitialData();
                    },
                    // ignore: deprecated_member_use
                    selectedColor: AppColors.primary.withOpacity(0.1),
                    checkmarkColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _onlyHealthPro
                          ? AppColors.primary
                          : Colors.black87,
                      fontWeight: _onlyHealthPro
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _onlyHealthPro
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: _daysLabel,
                    icon: Icons.keyboard_arrow_down,
                    isActive: _selectedDaysKey != 'todos',
                    onTap: _showDaysOptions,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: _timeLabel,
                    icon: Icons.keyboard_arrow_down,
                    isActive: _selectedTimeKey != 'qualquer',
                    onTap: _showTimeOptions,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading && _caregivers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _caregivers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhum profissional encontrado.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: _caregivers.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _caregivers.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: CaregiverCard(
                            caregiver: _caregivers[index],
                            onShowDetails: _showDetails,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
