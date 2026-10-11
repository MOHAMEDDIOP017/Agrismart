/// Jeux de données fixes partagés par les tests d'interface.
///
/// Les notifieurs réels sont sous-classés et seule leur méthode `build` est
/// redéfinie : les écrans voient la même forme de données qu'en production,
/// sans qu'aucun appel au serveur ne parte, et sans qu'un seul provider soit
/// modifié.
library;

import 'package:agritech/features/alertes/data/models/alerte_model.dart';
import 'package:agritech/features/alertes/presentation/providers/alertes_provider.dart';
import 'package:agritech/features/auth/domain/entities/user_entity.dart';
import 'package:agritech/features/auth/presentation/providers/auth_provider.dart';
import 'package:agritech/features/champs/domain/entities/champ_entity.dart';
import 'package:agritech/features/champs/presentation/providers/champ_provider.dart';
import 'package:agritech/features/chat/domain/entities/message_chat_entity.dart';
import 'package:agritech/features/chat/presentation/providers/chat_provider.dart';
import 'package:agritech/features/expert/domain/entities/recommandation_expert_entity.dart';
import 'package:agritech/features/expert/presentation/providers/expert_provider.dart';
import 'package:agritech/core/enums/statut_validation.dart';
import 'package:agritech/features/recommandations/data/models/recommandation_model.dart';
import 'package:agritech/features/recommandations/presentation/providers/derniere_recommandation_provider.dart';
import 'package:agritech/features/recommandations/presentation/providers/recommandation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Jeux de données ──────────────────────────────────────────────────────────

const utilisateurDemo = UserEntity(
  id: 'u1',
  nom: 'Diop',
  prenom: 'Mohamed',
  email: 'mohamed@exemple.sn',
  telephone: '770000000',
  zoneGeographique: 'Ngoundiane, Thiès',
);

final champsDemo = [
  ChampEntity(
    id: 'c1',
    nom: 'Champ Nord',
    superficie: 2.5,
    typeSol: 'Sableux',
    adresse: 'Ngoundiane',
    statut: 'EN_COURS',
    culture: 'Niébé',
    dateCreation: DateTime(2026, 5, 2),
  ),
  ChampEntity(
    id: 'c2',
    nom: 'Parcelle du bas',
    superficie: 1.2,
    typeSol: 'Argilo-sableux',
    adresse: 'Ngoundiane',
    statut: 'EN_COURS',
    culture: 'Mil',
    dateCreation: DateTime(2026, 5, 10),
  ),
  ChampEntity(
    id: 'c3',
    nom: 'Terrain de la route',
    superficie: 0.8,
    typeSol: 'Latéritique',
    adresse: 'Thiès',
    statut: 'PRÉVU',
    dateCreation: DateTime(2026, 6, 1),
  ),
];

final recoDemo = DerniereRecommandation(
  id: 'r1',
  champId: 'c1',
  champNom: 'Champ Nord',
  cultureNom: 'Niébé',
  aptitudePct: 87,
  periodePlantation: 'Semis de juin à juillet',
  zoneAgroecologique: 'Bassin arachidier',
  date: DateTime(2026, 6, 12),
);

class FauxAuth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const AuthState(user: utilisateurDemo, isAuthenticated: true);
}

class FauxChamps extends ChampNotifier {
  @override
  Future<List<ChampEntity>> build() async => champsDemo;
}

class FauxChampsVides extends ChampNotifier {
  @override
  Future<List<ChampEntity>> build() async => [];
}

class FaussesAlertes extends AlertesNotifier {
  @override
  Future<List<AlerteModel>> build() async => alertesDemo;
}

/// Trois alertes dont deux non lues, pour que la pastille de l'en-tête
/// apparaisse sur les captures.
final alertesDemo = [
  AlerteModel(
    id: 'a1',
    titre: 'Conseil de votre agronome',
    description: 'Surveillez le mildiou sur la parcelle du bas.',
    niveau: 'MODÉRÉ',
    champNom: 'Parcelle du bas',
    dateCreation: DateTime(2026, 6, 14),
  ),
  AlerteModel(
    id: 'a2',
    titre: 'Nouvelle recommandation',
    description: 'Trois cultures conseillées pour le Champ Nord.',
    niveau: 'FAIBLE',
    champNom: 'Champ Nord',
    dateCreation: DateTime(2026, 6, 12),
  ),
];

// ── Jeu de recommandations ───────────────────────────────────────────────────

RecommandationModel cultureDemo({
  required String nom,
  required int score,
  required int rang,
  required StatutValidation statut,
  required String periode,
  required double rendement,
}) =>
    RecommandationModel(
      id: 'r$rang',
      champId: 'c1',
      culture: nom,
      scoreCompatibilite: score,
      periodeIdealePlantation: periode,
      rendementEstime: rendement,
      besoinEau: 420,
      engAraisConseillesList: const ['NPK 15-15-15'],
      maladiesFrequentes: const ['Mildiou'],
      conseilsAgronomiques: 'Semer après la première pluie utile.',
      prixMarcheEstime: 250,
      profitPotentiel: 310000,
      dateGeneree: DateTime(2026, 6, 12),
      zoneAgroecologique: 'Bassin arachidier',
      rang: rang,
      statutValidation: statut,
    );

final resultatsDemo = RecommandationState(
  champIdSelectionne: 'c1',
  sourcesDonnees: const {
    'sol': 'SoilGrids (temps réel)',
    'climat': 'NASA POWER (temps réel)',
    'ndvi': 'moyenne de zone',
  },
  recommandations: [
    cultureDemo(
      nom: 'Niébé',
      score: 87,
      rang: 1,
      statut: StatutValidation.validee,
      periode: 'Semis de juin à juillet',
      rendement: 1.4,
    ),
    cultureDemo(
      nom: 'Mil',
      score: 64,
      rang: 2,
      statut: StatutValidation.enAttente,
      periode: 'Semis de juin à juillet',
      rendement: 0.9,
    ),
    cultureDemo(
      nom: 'Maïs',
      score: 38,
      rang: 3,
      statut: StatutValidation.enAttente,
      periode: 'Semis de juillet à août',
      rendement: 1.1,
    ),
  ],
);

/// Moteur de recommandation figé sur un état donné, pour les captures.
class FauxMoteur extends RecommandationNotifier {
  FauxMoteur(this._etat);

  final RecommandationState _etat;

  @override
  RecommandationState build() => _etat;
}

// ── Conversation de démonstration ────────────────────────────────────────────

final conversationDemo = ChatState(
  champIdCourant: 'c1',
  messages: [
    MessageChatEntity(
      role: RoleChat.utilisateur,
      contenu: 'Naka lay mengue mbay yi ci sama tool ?',
      horodatage: DateTime(2026, 6, 14, 9, 12),
    ),
    MessageChatEntity(
      role: RoleChat.assistant,
      contenu: 'Sur le Champ Nord, un sol sableux et les pluies attendues '
          'conviennent surtout au niébé (ñebbe). Le mil (dugub) reste '
          'possible si les pluies tardent.',
      horodatage: DateTime(2026, 6, 14, 9, 12),
    ),
    MessageChatEntity(
      role: RoleChat.utilisateur,
      contenu: 'Quand semer le niébé ?',
      horodatage: DateTime(2026, 6, 14, 9, 13),
    ),
  ],
  envoiEnCours: true,
);

class FauxChat extends ChatNotifier {
  FauxChat(this._etat);

  final ChatState _etat;

  @override
  ChatState build() => _etat;
}

// ── File de validation de démonstration ──────────────────────────────────────

CultureScoreEntity scoreDemo(String nom, double score, int rang) =>
    CultureScoreEntity(nom: nom, score: score, rang: rang);

final fileDemo = RecommandationsExpertState(
  filtre: 'EN_ATTENTE',
  recommandations: [
    RecommandationExpertEntity(
      id: 'x1',
      champId: 'c1',
      champNom: 'Champ Nord',
      champRegion: 'Thiès',
      agriculteurId: 'u1',
      agriculteurNom: 'Mohamed Diop',
      agriculteurTelephone: '770000000',
      top3Cultures: [
        scoreDemo('Niébé', 0.87, 1),
        scoreDemo('Mil', 0.64, 2),
        scoreDemo('Maïs', 0.38, 3),
      ],
      snapshot: const SnapshotAgronomique(),
      statutValidation: 'EN_ATTENTE',
      dateGeneree: DateTime(2026, 6, 12),
    ),
    RecommandationExpertEntity(
      id: 'x2',
      champId: 'c4',
      champNom: 'Parcelle Keur Massar',
      champRegion: 'Dakar',
      agriculteurId: 'u2',
      agriculteurNom: 'Fatou Ndiaye',
      agriculteurTelephone: '770000001',
      top3Cultures: [
        scoreDemo('Tomate', 0.79, 1),
        scoreDemo('Oignon', 0.71, 2),
        scoreDemo('Niébé', 0.52, 3),
      ],
      snapshot: const SnapshotAgronomique(),
      statutValidation: 'EN_ATTENTE',
      dateGeneree: DateTime(2026, 6, 11),
    ),
  ],
);

class FausseFile extends RecommandationsExpertNotifier {
  FausseFile(this._etat);

  final RecommandationsExpertState _etat;

  @override
  Future<RecommandationsExpertState> build() async => _etat;
}

// ── Remplacements de providers ───────────────────────────────────────────────
//
// Une liste par écran, pour que les planches et le contrôle de robustesse
// montent exactement le même arbre. Les notifieurs sont sous-classés : la
// logique de production reste en place, seule la source des données change.

/// Accueil de l'agriculteur. [avecChamps] et [avecReco] décrivent le premier
/// lancement, quand la personne n'a encore ni parcelle ni recommandation.
List<Override> donneesAccueil({bool avecChamps = true, bool avecReco = true}) =>
    [
      authProvider.overrideWith(FauxAuth.new),
      champProvider
          .overrideWith(avecChamps ? FauxChamps.new : FauxChampsVides.new),
      alertesProvider.overrideWith(FaussesAlertes.new),
      derniereRecommandationProvider
          .overrideWith((ref) => avecReco ? recoDemo : null),
    ];

/// Liste et détail d'une parcelle.
List<Override> donneesChamps({bool avecChamps = true}) => [
      authProvider.overrideWith(FauxAuth.new),
      champProvider
          .overrideWith(avecChamps ? FauxChamps.new : FauxChampsVides.new),
      champByIdProvider.overrideWith(
          (ref, id) async => champsDemo.firstWhere((c) => c.id == id)),
    ];

/// Résultat de recommandation, dans l'état passé en paramètre.
List<Override> donneesReco(RecommandationState etat) => [
      authProvider.overrideWith(FauxAuth.new),
      champProvider.overrideWith(FauxChamps.new),
      recommandationProvider.overrideWith(() => FauxMoteur(etat)),
    ];

/// Assistant conversationnel.
List<Override> donneesAssistant(ChatState etat) => [
      authProvider.overrideWith(FauxAuth.new),
      champProvider.overrideWith(FauxChamps.new),
      chatProvider.overrideWith(() => FauxChat(etat)),
    ];

/// File de validation de l'expert.
List<Override> donneesValidation(RecommandationsExpertState etat) => [
      authProvider.overrideWith(FauxAuth.new),
      recommandationsExpertProvider.overrideWith(() => FausseFile(etat)),
    ];
