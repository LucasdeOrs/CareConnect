import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/caregiver_profile.dart';

class CaregiverCard extends StatelessWidget {
  final CaregiverProfile caregiver;
  final void Function(CaregiverProfile) onShowDetails;

  const CaregiverCard({
    super.key,
    required this.caregiver,
    required this.onShowDetails,
  });

  static const Icon _healthIcon = Icon(
    Icons.health_and_safety,
    color: Colors.blue,
    size: 16,
  );

  Widget _buildStarRating(double rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      stars.add(
        Icon(
          i <= rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        ),
      );
    }
    return Row(children: stars);
  }

  Widget _buildInfoChip(
    BuildContext context,
    String text,
    Color iconColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: (caregiver.avatarUrl != null)
                      ? NetworkImage(caregiver.avatarUrl!)
                      : null,
                  child: (caregiver.avatarUrl == null)
                      ? Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.grey.shade600,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              caregiver.nome,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (caregiver.formacaoSaude) ...[
                            const SizedBox(width: 6),
                            _healthIcon,
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      if (caregiver.profissao != null &&
                          caregiver.profissao!.isNotEmpty)
                        Text(
                          caregiver.profissao!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.indigo,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (caregiver.profissao == null ||
                          caregiver.profissao!.isEmpty)
                        Text(
                          caregiver.especialidades.join(', '),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          _buildStarRating(caregiver.avaliacaoMedia),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${caregiver.city}, ${caregiver.state}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24, thickness: 0.5),

            Row(
              children: [
                _buildInfoChip(
                  context,
                  caregiver.availabilityText,
                  Colors.grey.shade700,
                ),
                const Spacer(),
                _buildInfoChip(
                  context,
                  '${currencyFormat.format(caregiver.hourlyRate)}/h',
                  Colors.green.shade800,
                ),
              ],
            ),

            const SizedBox(height: 16),

            FilledButton.tonal(
              onPressed: () => onShowDetails(caregiver),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text('Ver Detalhes'),
            ),
          ],
        ),
      ),
    );
  }
}
