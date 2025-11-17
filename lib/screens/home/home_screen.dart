import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/screens/appointment/appointments_screen.dart';
import 'package:careconnect_app/screens/chat/inbox_screen.dart';
import 'package:careconnect_app/screens/home/widgets/caregiver_detail_modal.dart';
import 'package:careconnect_app/screens/profile/profile_screen.dart';
import 'package:careconnect_app/services/caregiver_service.dart';
import 'package:careconnect_app/services/location_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/caregiver_profile.dart';
import 'widgets/app_drawer.dart';
import '../../core/widgets/cards/caregiver_card.dart';
import '../../core/widgets/logo_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final CaregiverService _caregiverService = CaregiverService();

  CaregiverProfile? _selectedCaregiver;

  String _currentView = 'home';
  String _previousView = 'home';

  final _searchController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _cidadeUFController = TextEditingController();
  RangeValues _priceRange = const RangeValues(0, 500);
  bool _filtraFormacaoSaude = false;
  String? _selectedAvailability;
  String? _selectedTimePeriod;
  String _sortOrder = 'rating_desc';
  final Map<String, String> _sortLabels = {
    'rating_desc': 'Melhores avaliados',
    'rating_asc': 'Piores avaliados',
    'price_asc': 'Menor preço',
    'price_desc': 'Maior preço',
  };

  final _scrollController = ScrollController();
  final List<CaregiverProfile> _caregivers = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _showAdvancedFilters = false;

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

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _cidadeUFController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _currentPage = 0;
      _caregivers.clear();
      _hasMore = true;
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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _cityController.clear();
      _stateController.clear();
      _cidadeUFController.clear();
      _priceRange = const RangeValues(0, 500);
      _filtraFormacaoSaude = false;
      _selectedAvailability = null;
      _sortOrder = 'rating_desc';
    });
    _loadInitialData();
  }

  Future<void> _fetchCaregivers() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final from = _currentPage * _pageSize;

    try {
      final List<CaregiverProfile> newCaregivers = await _caregiverService
          .getCaregivers(
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
            onlyHealthProfessionals: _filtraFormacaoSaude,
            availability: _selectedAvailability,
            sortOrder: _sortOrder,
            limit: _pageSize,
            offset: from,
          );

      if (newCaregivers.length < _pageSize) {
        _hasMore = false;
      }

      if (mounted) {
        setState(() {
          _caregivers.addAll(newCaregivers);
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar cuidadores: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _carregarCidades() async {
    if (LocationService.citiesCache.isNotEmpty) {
      setState(() {
        _todasCidadesComUF = LocationService.citiesCache;
      });
      return;
    }

    if (_isLocalLoading) return;

    if (mounted) setState(() => _isLocalLoading = true);
    try {
      _todasCidadesComUF = await LocationService.getBrazilianCities();
    } catch (e) {
      debugPrint("Erro ao carregar cidades: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocalLoading = false);
      }
    }
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'appointments':
        return AppointmentsScreen(
          onClose: () => setState(() {
            _currentView = 'home';
            _selectedCaregiver = null;
          }),
        );
      case 'details':
        if (_selectedCaregiver != null) {
          return CaregiverDetailModal(
            caregiver: _selectedCaregiver!,
            onClose: () {
              setState(() {
                _selectedCaregiver = null;
                _currentView = _previousView;
              });
            },
          );
        }
        return _buildListView();
      case 'profile':
        return ProfileScreen(
          onClose: () => setState(() {
            _currentView = 'home';
            _selectedCaregiver = null;
          }),
          onShowPublicProfile: (caregiverProfile) {
            setState(() {
              _previousView = _currentView;
              _selectedCaregiver = caregiverProfile;
              _currentView = 'details';
            });
          },
        );

      case 'messages':
        return const InboxScreen();

      case 'home':
      default:
        return _buildListView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const LogoWidget(size: 110, useAlternative: true),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      drawer: AppDrawer(
        onNavigate: (String route) {
          Navigator.pop(context);
          if (route == 'appointments') {
            setState(() => _currentView = 'appointments');
          } else if (route == 'home') {
            setState(() {
              _currentView = 'home';
              _selectedCaregiver = null;
            });
          } else if (route == 'profile') {
            setState(() => _currentView = 'profile');
          }
        },
      ),
      body: _buildCurrentView(),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        _buildFilterContainer(),
        _buildSortControl(),
        Expanded(child: _buildResultsList()),
      ],
    );
  }

  Widget _buildFilterContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Buscar profissional...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showAdvancedFilters
                ? _buildAdvancedFilters()
                : const SizedBox(width: double.infinity, height: 0),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _showAdvancedFilters ? Icons.expand_less : Icons.expand_more,
                ),
                tooltip: _showAdvancedFilters
                    ? 'Ocultar filtros'
                    : 'Mostrar filtros',
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = !_showAdvancedFilters;
                  });
                },
              ),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Pesquisar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _loadInitialData,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.cleaning_services),
                tooltip: 'Limpar filtros',
                onPressed: _clearFilters,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _cidadeUFController.text),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (_isLocalLoading) return ["Carregando cidades..."];
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            final query = textEditingValue.text.toLowerCase();
            return _todasCidadesComUF.where((String option) {
              return option.toLowerCase().contains(query);
            });
          },
          onSelected: (String selection) {
            final parts = selection.split(', ');
            if (parts.length == 2) {
              _cityController.text = parts[0];
              _stateController.text = parts[1];
              _cidadeUFController.text = selection;
            }
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmit) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Cidade e Estado',
                hintText: 'Ex: São Paulo, SP',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _isLocalLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: _selectedAvailability,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: null, child: Text('Qualquer Dia')),
            DropdownMenuItem(
              value: "Dias de Semana",
              child: Text('Dias de semana'),
            ),
            DropdownMenuItem(
              value: "Finais de Semana",
              child: Text('Finais de semana'),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedAvailability = value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: _selectedTimePeriod,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: null, child: Text('Qualquer Período')),
            DropdownMenuItem(value: 'dia', child: Text('Período do Dia')),
            DropdownMenuItem(value: 'tarde', child: Text('Período da Tarde')),
            DropdownMenuItem(value: 'noite', child: Text('Período da Noite')),
          ],
          onChanged: (value) {
            setState(() => _selectedTimePeriod = value);
          },
        ),
        CheckboxListTile(
          value: _filtraFormacaoSaude,
          onChanged: (bool? value) {
            setState(() {
              _filtraFormacaoSaude = value ?? false;
            });
          },
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Row(
            children: [
              const Text(
                'Profissional da saúde',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Icon(Icons.health_and_safety, color: AppColors.primary, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Preço/h: ', style: TextStyle(fontSize: 12)),
            Text(
              'R\$${_priceRange.start.round()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: RangeSlider(
                values: _priceRange,
                min: 0,
                max: 500,
                divisions: 50,
                activeColor: AppColors.primary,
                labels: RangeLabels(
                  'R\$${_priceRange.start.round()}',
                  'R\$${_priceRange.end.round()}',
                ),
                onChanged: (values) {
                  setState(() => _priceRange = values);
                },
              ),
            ),
            Text(
              'R\$${_priceRange.end.round()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortControl() {
    final currentLabel = _sortLabels[_sortOrder] ?? 'Ordenar';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_vert),
            tooltip: 'Ordenar por',
            onSelected: (String value) {
              setState(() {
                _sortOrder = value;
              });
              _loadInitialData();
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'rating_desc',
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 18,
                        color: _sortOrder == 'rating_desc'
                            ? AppColors.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('Melhores avaliados'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'rating_asc',
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 18,
                        color: _sortOrder == 'rating_asc'
                            ? AppColors.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('Piores avaliados'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'price_asc',
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 18,
                        color: _sortOrder == 'price_asc'
                            ? AppColors.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('Menor preço'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'price_desc',
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 18,
                        color: _sortOrder == 'price_desc'
                            ? AppColors.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('Maior preço'),
                    ],
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 8),
          Text(
            currentLabel,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading && _caregivers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_caregivers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Nenhum cuidador encontrado.\nTente ajustar seus filtros.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _caregivers.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _caregivers.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final caregiver = _caregivers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: CaregiverCard(
            caregiver: caregiver,
            onShowDetails: (selectedProfile) {
              setState(() {
                _previousView = _currentView;
                _selectedCaregiver = selectedProfile;
                _currentView = 'details';
              });
            },
          ),
        );
      },
    );
  }
}
