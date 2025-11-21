import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/utils/app_formatters.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:careconnect_app/screens/appointment/appointment_form_modal.dart';
import 'package:careconnect_app/screens/chat/chat_screen.dart';
import 'package:careconnect_app/services/auth_service.dart';
import 'package:careconnect_app/services/chat_service.dart';
import 'package:careconnect_app/services/review_service.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;

  const ExpandableText({super.key, required this.text, this.maxLines = 3});

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodyLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: expanded ? null : widget.maxLines,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: defaultStyle,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => expanded = !expanded),
          child: Text(
            expanded ? "ver menos" : "ver mais",
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class CaregiverDetailModal extends StatefulWidget {
  final CaregiverProfile caregiver;
  final VoidCallback onClose;

  const CaregiverDetailModal({
    super.key,
    required this.caregiver,
    required this.onClose,
  });

  @override
  State<CaregiverDetailModal> createState() => _CaregiverDetailModalState();
}

class _CaregiverDetailModalState extends State<CaregiverDetailModal> {
  final AuthService _authService = AuthService();
  final ReviewService _reviewService = ReviewService();

  late final Future<List<Map<String, dynamic>>> _reviewsFuture;
  bool _isViewerCaregiver = false;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _reviewService.getReviewsForCaregiver(widget.caregiver.id);
    _checkViewerType();
  }

  void _checkViewerType() {
    final user = _authService.currentUser;
    if (user != null) {
      final tipo = user.userMetadata?['tipo'];
      setState(() {
        _isViewerCaregiver = (tipo == 'cuidador');
      });
    }
  }

  Future<void> _openChat() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;
    try {
      final conversaId = await ChatService.startConversation(
        familiarId: currentUser.id,
        cuidadorId: widget.caregiver.id,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversaId: conversaId,
              otherUserName: widget.caregiver.nome,
              otherUserAvatar: widget.caregiver.avatarUrl,
              currentUserId: currentUser.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  static const Icon _healthIcon = Icon(
    Icons.health_and_safety,
    color: AppColors.primary,
    size: 20,
  );

  String _ensureFullUrl(String rawUrl) {
    if (rawUrl.startsWith('http')) {
      return rawUrl;
    }

    return supabase.storage.from('cuidadores').getPublicUrl(rawUrl);
  }

  Widget _buildHeaderStarRating(double rating, {int reviewCount = 0}) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      stars.add(
        Icon(
          i <= rating ? Icons.star : Icons.star_border,
          color: AppColors.warning,
          size: 24,
        ),
      );
    }

    stars.add(const SizedBox(width: 8));
    stars.add(
      Text(
        '($reviewCount ${reviewCount == 1 ? 'avaliação' : 'avaliações'})',
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
    );

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: stars);
  }

  Widget _buildCommentStarRating(int rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      stars.add(
        Icon(
          i <= rating ? Icons.star : Icons.star_border,
          color: AppColors.warning,
          size: 16,
        ),
      );
    }
    return Row(children: stars);
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = AppFormatters.currency;

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: widget.onClose,
            tooltip: 'Voltar para a lista',
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _reviewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao carregar avaliações: ${snapshot.error}'),
                );
              }

              final reviews = snapshot.data ?? [];

              double currentAverage = 0.0;
              int reviewCount = reviews.length;
              if (reviewCount > 0) {
                double totalRating = reviews.fold(
                  0.0,
                  (sum, item) => sum + (item['nota'] as num),
                );
                currentAverage = totalRating / reviewCount;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      child: (widget.caregiver.avatarUrl == null)
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey.shade600,
                            )
                          : ClipOval(
                              child: Image.network(
                                widget.caregiver.avatarUrl!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.caregiver.nome,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (widget.caregiver.formacaoSaude)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _healthIcon,
                            const SizedBox(width: 8),
                            Text(
                              'Profissional formado na área da saúde',
                              style: TextStyle(
                                color: AppColors.primary.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    _buildHeaderStarRating(
                      currentAverage,
                      reviewCount: reviewCount,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        "${widget.caregiver.city}, ${widget.caregiver.state}",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.black54),
                      ),
                    ),
                    const Divider(height: 40),
                    if (widget.caregiver.profissao != null &&
                        widget.caregiver.profissao!.isNotEmpty)
                      _buildInfoRow(
                        context,
                        Icons.school,
                        'Profissão',
                        widget.caregiver.profissao!,
                      ),
                    _buildSpecialtiesList(
                      context,
                      widget.caregiver.especialidades,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.work_history,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Experiência',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                ExpandableText(
                                  text:
                                      widget.caregiver.experiencia ??
                                      'Não informado',
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildInfoRow(
                      context,
                      Icons.calendar_today,
                      'Anos de Experiência',
                      '${widget.caregiver.experienceYears} anos',
                    ),
                    if (widget.caregiver.age != null)
                      _buildInfoRow(
                        context,
                        Icons.cake,
                        'Idade',
                        '${widget.caregiver.age} anos',
                      ),
                    _buildInfoRow(
                      context,
                      Icons.schedule,
                      'Disponibilidade',
                      widget.caregiver.availabilityText,
                    ),
                    _buildInfoRow(
                      context,
                      Icons.attach_money,
                      'Preço por Hora',
                      currencyFormat.format(widget.caregiver.hourlyRate),
                    ),
                    if (widget.caregiver.certificados.isNotEmpty)
                      _buildCertificados(context),
                    const Divider(height: 40),

                    if (!_isViewerCaregiver)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Agendar / Contratar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (context) => AppointmentFormModal(
                              caregiver: widget.caregiver,
                            ),
                          );
                        },
                      ),

                    SizedBox(height: _isViewerCaregiver ? 0 : 12),

                    OutlinedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Entrar em Contato'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      onPressed: _openChat,
                    ),
                    const Divider(height: 40),
                    _buildReviewSection(context, reviews),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection(
    BuildContext context,
    List<Map<String, dynamic>> reviews,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avaliações de Usuários',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (reviews.isEmpty)
          const Center(
            child: Text(
              'Nenhuma avaliação ainda.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          )
        else
          Column(
            children: reviews
                .map((review) => _ReviewCommentCard(reviewData: review))
                .toList(),
          ),
      ],
    );
  }

  // ignore: non_constant_identifier_names
  Widget _ReviewCommentCard({required Map<String, dynamic> reviewData}) {
    final familiar = reviewData['familiar'] as Map<String, dynamic>? ?? {};
    final nomeFamiliar = familiar['nome'] ?? 'Usuário';
    final avatarFamiliar = familiar['avatar_url'] as String?;
    final nota = (reviewData['nota'] as num).toInt();
    final comentario = reviewData['comentario'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: (avatarFamiliar != null)
                    ? NetworkImage(avatarFamiliar)
                    : null,
                child: (avatarFamiliar == null)
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nomeFamiliar,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _buildCommentStarRating(nota),
            ],
          ),
          if (comentario != null && comentario.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                comentario,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesList(BuildContext context, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person_search, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Especialidades',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...items.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        const Text("• ", style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            e,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificados(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.workspace_premium,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Certificados & Documentos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...widget.caregiver.certificados.map((certData) {
                  final rawUrl = certData['url'] ?? '';
                  final fileName = certData['name'] ?? 'Certificado';

                  if (rawUrl.isEmpty) return const SizedBox.shrink();

                  return InkWell(
                    onTap: () {
                      final validUrl = _ensureFullUrl(rawUrl);

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => FullScreenImageViewer(
                            imageUrl: validUrl,
                            title: fileName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.remove_red_eye,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fileName,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String title;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.broken_image, color: Colors.white54, size: 50),
                  SizedBox(height: 8),
                  Text(
                    "Não foi possível carregar a imagem.",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
