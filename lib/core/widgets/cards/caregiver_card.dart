import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/utils/app_formatters.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:flutter/material.dart';

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
    color: AppColors.primary,
    size: 16,
  );

  Widget _buildStarRating(double rating) {
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
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }

  Widget _buildInfoChip(String text, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesRow() {
    final features = <Widget>[];

    if (caregiver.possuiCarro) {
      features.add(_buildFeatureBadge(Icons.directions_car, 'Carro'));
    } else if (caregiver.habilitaCnh) {
      features.add(_buildFeatureBadge(Icons.credit_card, 'CNH'));
    }

    if (caregiver.dormirLocal) {
      features.add(_buildFeatureBadge(Icons.bedtime, 'Dorme'));
    }

    if (caregiver.cozinha) {
      features.add(_buildFeatureBadge(Icons.soup_kitchen, 'Cozinha'));
    }

    if (features.isEmpty && !caregiver.fumante) {
      features.add(_buildFeatureBadge(Icons.smoke_free, 'Não Fuma'));
    }

    if (features.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(runSpacing: 4, children: features.take(3).toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = AppFormatters.currency;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        child: InkWell(
          onTap: () => onShowDetails(caregiver),
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage:
                            (caregiver.avatarUrl != null &&
                                caregiver.avatarUrl!.isNotEmpty)
                            ? NetworkImage(caregiver.avatarUrl!)
                            : null,
                        child:
                            (caregiver.avatarUrl == null ||
                                caregiver.avatarUrl!.isEmpty)
                            ? const Icon(
                                Icons.person,
                                size: 28,
                                color: Colors.grey,
                              )
                            : null,
                      ),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (caregiver.formacaoSaude) ...[
                                const SizedBox(width: 4),
                                _healthIcon,
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),

                          Text(
                            caregiver.profissao != null &&
                                    caregiver.profissao!.isNotEmpty
                                ? caregiver.profissao!
                                : (caregiver.especialidades.isNotEmpty
                                      ? caregiver.especialidades.first
                                      : 'Cuidador'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 6),

                          Row(
                            children: [
                              _buildStarRating(caregiver.avaliacaoMedia),
                              if (caregiver.avaliacaoMedia > 0)
                                Text(
                                  " ${caregiver.avaliacaoMedia.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              const Spacer(),
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  caregiver.city ?? 'Local n/d',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                _buildFeaturesRow(),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(height: 1, thickness: 0.5),
                ),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        caregiver.availabilityText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildInfoChip(
                      '${currencyFormat.format(caregiver.hourlyRate)}/h',
                      AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
