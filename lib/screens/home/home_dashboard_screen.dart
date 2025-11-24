import 'dart:async';
import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:careconnect_app/screens/caregiver_list/caregiver_detail_modal.dart';
import 'package:careconnect_app/screens/chat/inbox_screen.dart';
import 'package:careconnect_app/screens/notifications/notifications_screen.dart';
import 'package:careconnect_app/screens/profile/familiar_screens/my_patients_screen.dart';
import 'package:careconnect_app/screens/settings/help_center_screen.dart';
import 'package:careconnect_app/services/auth_service.dart';
import 'package:careconnect_app/services/caregiver_service.dart';
import 'package:careconnect_app/services/notification_service.dart';
import 'package:flutter/material.dart';

class HomeDashboardScreen extends StatefulWidget {
  final Function({
    String? query,
    bool? healthPro,
    String? time,
    String? sort,
    bool? possuiCarro,
    bool? cozinha,
    bool? limpeza,
    bool? dormirLocal,
    bool? gostaAnimais,
  })?
  onSearchCategory;

  final Function(int index)? onTabChange;

  const HomeDashboardScreen({
    super.key,
    this.onSearchCategory,
    this.onTabChange,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final AuthService _authService = AuthService();
  final CaregiverService _caregiverService = CaregiverService();
  final NotificationService _notificationService = NotificationService();

  String _userName = '';
  bool _isCaregiver = false;
  late Future<List<CaregiverProfile>> _topCaregiversFuture;
  Stream<List<Map<String, dynamic>>>? _notificationsStream;

  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;
  Timer? _carouselTimer;

  bool _isMenuExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _topCaregiversFuture = _fetchTopCaregivers();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentBannerIndex + 1;
        if (nextPage > 2) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _loadUserData() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.userMetadata?['nome']?.split(' ').first ?? 'Visitante';
        final tipo = user.userMetadata?['tipo'] ?? '';
        _isCaregiver = tipo == 'cuidador';
        _notificationsStream = _notificationService.getNotificationsStream(
          user.id,
        );
      });
    }
  }

  Future<List<CaregiverProfile>> _fetchTopCaregivers() {
    return _caregiverService.getCaregivers(sortOrder: 'rating_desc', limit: 5);
  }

  void _showCaregiverDetails(CaregiverProfile profile) {
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

  void _handleCategoryTap(Map<String, dynamic> item) {
    final String label = item['label'];

    if (label == 'Ver mais' || label == 'Ver menos') {
      setState(() {
        _isMenuExpanded = !_isMenuExpanded;
      });
      return;
    }

    switch (label) {
      case 'Cuidador':
        widget.onSearchCategory?.call(query: '');
        break;
      case 'Enfermeiro':
        widget.onSearchCategory?.call(query: 'Enfermeiro', healthPro: true);
        break;
      case 'Com Carro':
        widget.onSearchCategory?.call(possuiCarro: true);
        break;
      case 'Dorme no Local':
        widget.onSearchCategory?.call(dormirLocal: true);
        break;
      case 'Cozinha':
        widget.onSearchCategory?.call(cozinha: true);
        break;
      case 'Limpeza':
        widget.onSearchCategory?.call(limpeza: true);
        break;
      case 'Pet Friendly':
        widget.onSearchCategory?.call(gostaAnimais: true);
        break;
      case 'Agenda':
        widget.onTabChange?.call(2);
        break;
      case 'Meus Pacientes':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyPatientsScreen()),
        );
        break;
      case 'Chat':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InboxScreen()),
        );
        break;
      case 'Melhores':
        widget.onSearchCategory?.call(sort: 'rating_desc');
        break;
      case 'Ajuda':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Olá, $_userName',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _notificationsStream,
              builder: (context, snapshot) {
                int unreadCount = 0;
                if (snapshot.hasData) {
                  unreadCount = snapshot.data!
                      .where((n) => n['is_read'] == false)
                      .length;
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.notifications_none,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 160,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
              children: [
                _buildBanner(
                  title: 'Cuidado que\nconecta.',
                  subtitle: 'Encontre o profissional ideal hoje.',
                  icon: Icons.medical_services,
                  gradientColors: [
                    AppColors.primary,
                    AppColors.primary.shade300,
                  ],
                  onTap: () {
                    widget.onTabChange?.call(1);
                  },
                ),
                _buildBanner(
                  title: 'Cupom de\nBoas-vindas',
                  subtitle: 'Use PRIMEIRA10 e ganhe 10% off.',
                  icon: Icons.local_offer,
                  gradientColors: [Colors.orange, Colors.deepOrange],
                  onTap: null,
                ),
                _buildBanner(
                  title: 'Precisa de\nAjuda?',
                  subtitle: 'Consulte nossa Central de Dúvidas.',
                  icon: Icons.support_agent,
                  gradientColors: [Colors.teal, Colors.teal.shade300],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpCenterScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: _currentBannerIndex == index ? 12 : 6,
                decoration: BoxDecoration(
                  color: _currentBannerIndex == index
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          const Text(
            'Categorias',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCategoryGrid(),
          const SizedBox(height: 24),
          const Text(
            'Destaques da Semana',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: FutureBuilder<List<CaregiverProfile>>(
              future: _topCaregiversFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Erro ao carregar.'));
                }

                final caregivers = snapshot.data ?? [];

                if (caregivers.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum destaque encontrado.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: caregivers.length,
                  itemBuilder: (context, index) {
                    final caregiver = caregivers[index];
                    return GestureDetector(
                      onTap: () => _showCaregiverDetails(caregiver),
                      child: Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 12, bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: caregiver.avatarUrl != null
                                      ? Image.network(
                                          caregiver.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.grey.shade400,
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    caregiver.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        caregiver.avaliacaoMedia
                                            .toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
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
          ),
        ],
      ),
    );
  }

  Widget _buildBanner({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 150,
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final List<Map<String, dynamic>> basicItems = [
      {'icon': Icons.elderly, 'label': 'Cuidador', 'color': Colors.orange},
      {
        'icon': Icons.health_and_safety,
        'label': 'Enfermeiro',
        'color': Colors.blue,
      },
      {
        'icon': Icons.bedtime,
        'label': 'Dorme no Local',
        'color': Colors.indigo,
      },
      {
        'icon': Icons.directions_car,
        'label': 'Com Carro',
        'color': Colors.green,
      },
      {'icon': Icons.soup_kitchen, 'label': 'Cozinha', 'color': Colors.red},
      {
        'icon': Icons.cleaning_services,
        'label': 'Limpeza',
        'color': Colors.teal,
      },
      {'icon': Icons.pets, 'label': 'Pet Friendly', 'color': Colors.brown},
    ];

    final List<Map<String, dynamic>> expandedItems = [];

    expandedItems.add({
      'icon': Icons.healing,
      'label': 'Pós-Cirúrgico',
      'color': Colors.greenAccent,
    });
    expandedItems.add({
      'icon': Icons.volunteer_activism,
      'label': 'Companhia',
      'color': Colors.pinkAccent,
    });

    expandedItems.add({
      'icon': Icons.calendar_month,
      'label': 'Agenda',
      'color': Colors.indigo,
    });

    if (!_isCaregiver) {
      expandedItems.add({
        'icon': Icons.people,
        'label': 'Meus Pacientes',
        'color': Colors.cyan,
      });
    }

    expandedItems.add({
      'icon': Icons.chat,
      'label': 'Chat',
      'color': Colors.deepPurple,
    });
    expandedItems.add({
      'icon': Icons.star,
      'label': 'Melhores',
      'color': Colors.amber,
    });
    expandedItems.add({
      'icon': Icons.help,
      'label': 'Ajuda',
      'color': Colors.blueGrey,
    });

    final List<Map<String, dynamic>> displayItems = List.from(basicItems);

    if (_isMenuExpanded) {
      displayItems.addAll(expandedItems);
      displayItems.add({
        'icon': Icons.expand_less,
        'label': 'Ver menos',
        'color': Colors.grey,
      });
    } else {
      displayItems.add({
        'icon': Icons.more_horiz,
        'label': 'Ver mais',
        'color': Colors.grey,
      });
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: GridView.builder(
        key: ValueKey(_isMenuExpanded),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final item = displayItems[index];

          final isExpandedItem = expandedItems.any(
            (e) => e['label'] == item['label'],
          );

          Widget content = GestureDetector(
            onTap: () => _handleCategoryTap(item),
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['label'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );

          if (_isMenuExpanded && isExpandedItem) {
            final delay = (index - basicItems.length) * 50;
            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + delay),
              curve: Curves.easeOutBack,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                );
              },
              child: content,
            );
          }

          return content;
        },
      ),
    );
  }
}
