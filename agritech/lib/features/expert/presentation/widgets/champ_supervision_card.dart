import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/champ_supervise_entity.dart';
import '../../../../shared/widgets/widgets.dart';

/// Carte de supervision d'un champ pour l'Expert
class ChampSupervisionCard extends StatelessWidget {
  const ChampSupervisionCard({
    super.key,
    required this.champ,
    required this.onTableauDeBord,
  });

  final ChampSuperviseEntity champ;
  final VoidCallback onTableauDeBord;

  Color _couleurSante(BuildContext context) {
    if (champ.scoresSante >= 70) return context.couleurs.primaire;
    if (champ.scoresSante >= 40) return context.couleurs.secondaire;
    return context.couleurs.erreur;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Image champ
          if (champ.photoUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                champ.photoUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imgPlaceholder(context),
              ),
            )
          else
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: _imgPlaceholder(context),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        champ.nom,
                        style: AppTypography.police(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.couleurs.textePrincipal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    BadgeStatut.statutChamp(champ.statut),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${champ.agriculteurNom} · ${champ.superficieFormatee}',
                  style: AppTypography.police(
                      fontSize: 12, color: context.couleurs.texteSecondaire),
                ),
                if (champ.culture != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${champ.culture} · ${champ.typeSol}',
                    style: AppTypography.police(
                        fontSize: 11, color: context.couleurs.texteSecondaire),
                  ),
                ],
                if (champ.derniereAlerte != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: context.couleurs.erreur.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_outlined,
                            size: 14, color: context.couleurs.erreur),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            champ.derniereAlerte!,
                            style: AppTypography.police(
                              fontSize: 11,
                              color: context.couleurs.erreur,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Score santé
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Santé du champ',
                      style: AppTypography.police(
                          fontSize: 12,
                          color: context.couleurs.texteSecondaire),
                    ),
                    Text(
                      '${champ.scoresSante}%',
                      style: AppTypography.police(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _couleurSante(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: champ.scoresSante / 100,
                    backgroundColor:
                        _couleurSante(context).withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(_couleurSante(context)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTableauDeBord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.couleurs.primaire,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: AppTypography.police(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Tableau de bord'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder(BuildContext context) => Container(
        height: 100,
        color: context.couleurs.bordure,
        child: Center(
            child: Icon(Icons.terrain,
                color: context.couleurs.texteSecondaire, size: 36)),
      );
}
