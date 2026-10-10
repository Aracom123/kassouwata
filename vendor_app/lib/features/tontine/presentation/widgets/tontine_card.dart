import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/tontine_entity.dart';

class TontineCard extends StatelessWidget {
  final TontineEntity tontine;
  final VoidCallback onTap;

  const TontineCard({super.key, required this.tontine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.savings_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tontine.libelle,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tontine.description != null &&
                        tontine.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        tontine.description!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _chip(
                          context,
                          '${tontine.montant.toStringAsFixed(0)} F/membre',
                          theme.colorScheme.primary,
                          theme.colorScheme.primaryContainer,
                        ),
                        if (tontine.periodicite != null)
                          _chip(
                            context,
                            tontine.periodicite!,
                            theme.colorScheme.secondary,
                            theme.colorScheme.secondaryContainer,
                          ),
                      ],
                    ),
                    if (tontine.dateDebut != null || tontine.dateFin != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            _formatDates(tontine, dateFormat),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(
      BuildContext context, String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  String _formatDates(TontineEntity t, DateFormat fmt) {
    if (t.dateDebut != null && t.dateFin != null) {
      return '${fmt.format(t.dateDebut!)} → ${fmt.format(t.dateFin!)}';
    } else if (t.dateDebut != null) {
      return 'Début : ${fmt.format(t.dateDebut!)}';
    } else {
      return 'Fin : ${fmt.format(t.dateFin!)}';
    }
  }
}