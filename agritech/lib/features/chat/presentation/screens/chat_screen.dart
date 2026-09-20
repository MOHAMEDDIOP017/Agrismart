import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';

/// Écran de chat avec l'agent conversationnel AgriSmart (français / wolof)
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollVersLeBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _envoyer() async {
    final texte = _controller.text;
    if (texte.trim().isEmpty) return;
    _controller.clear();
    await ref.read(chatProvider.notifier).envoyer(texte);
    _scrollVersLeBas();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);
    // Fait défiler vers le bas à chaque nouveau message (envoi ou réponse).
    ref.listen(chatProvider, (_, __) => _scrollVersLeBas());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant AgriSmart'),
        actions: [
          if (state.messages.isNotEmpty)
            IconButton(
              tooltip: 'Nouvelle conversation',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.read(chatProvider.notifier).reinitialiser(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _AccueilVide(
                    onSuggestion: (texte) =>
                        ref.read(chatProvider.notifier).envoyer(texte),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length + (state.envoiEnCours ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: TypingIndicator(),
                        );
                      }
                      return MessageBubble(message: state.messages[index]);
                    },
                  ),
          ),
          _BarreDeSaisie(
            controller: _controller,
            enCours: state.envoiEnCours,
            onEnvoyer: _envoyer,
          ),
        ],
      ),
    );
  }
}

class _AccueilVide extends StatelessWidget {
  const _AccueilVide({required this.onSuggestion});

  final void Function(String) onSuggestion;

  static const _suggestions = [
    'Quelles cultures pour Kaolack ?',
    'Comment traiter le mildiou de la tomate ?',
    'Naka lay mengue mbay yi ci Ziguinchor ?', // wolof : quelles cultures à Ziguinchor
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyStateWidget(
              title: 'Posez votre question',
              message:
                  'L\'assistant AgriSmart répond en français ou en wolof, et peut '
                  'recommander les cultures adaptées à votre localité.',
              icon: Icons.forum_outlined,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions
                  .map((s) => ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        onPressed: () => onSuggestion(s),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarreDeSaisie extends StatelessWidget {
  const _BarreDeSaisie({
    required this.controller,
    required this.enCours,
    required this.onEnvoyer,
  });

  final TextEditingController controller;
  final bool enCours;
  final VoidCallback onEnvoyer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onEnvoyer(),
                decoration: InputDecoration(
                  hintText: 'Écrivez en français ou en wolof...',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: enCours
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: enCours ? null : onEnvoyer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
