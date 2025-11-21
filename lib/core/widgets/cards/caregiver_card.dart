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
          size: 18,
        ),
      );
    }
    return Row(children: stars);
  }

  Widget _buildInfoChip(String text, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = AppFormatters.currency;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () => onShowDetails(caregiver),
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
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage:
                        (caregiver.avatarUrl != null &&
                            caregiver.avatarUrl!.isNotEmpty)
                        ? NetworkImage(caregiver.avatarUrl!)
                        : null,
                    child:
                        (caregiver.avatarUrl == null ||
                            caregiver.avatarUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 30, color: Colors.grey)
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
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            caregiver.especialidades.isNotEmpty
                                ? caregiver.especialidades.join(', ')
                                : 'Especialidades não informadas',
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
                                  caregiver.location,
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
                    caregiver.availabilityText,
                    Colors.grey.shade700,
                  ),
                  const Spacer(),
                  _buildInfoChip(
                    '${currencyFormat.format(caregiver.hourlyRate)}/h',
                    AppColors.success,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
