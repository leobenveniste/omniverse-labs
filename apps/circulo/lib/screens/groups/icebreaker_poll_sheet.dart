import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/circle_group_model.dart';
import '../../services/auth_service.dart';
import '../../services/online_firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_feedback_components.dart';
import '../../l10n/app_localizations.dart';

class IcebreakerPollSheet extends StatefulWidget {
  final CircleGroupModel group;

  const IcebreakerPollSheet({super.key, required this.group});

  @override
  State<IcebreakerPollSheet> createState() => _IcebreakerPollSheetState();
}

class _IcebreakerPollSheetState extends State<IcebreakerPollSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _pollQuestionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(text: 'Sábado por la tarde'),
    TextEditingController(text: 'Domingo al mediodía'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollQuestionCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _sendIcebreaker(String prompt) async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    final firestore = context.read<OnlineFirestoreService>();

    await firestore.sendMessage(GroupMessageModel(
      id: const Uuid().v4(),
      groupId: widget.group.id,
      senderId: user.id,
      senderName: user.firstName,
      type: 'icebreaker',
      text: '🎲 Rompehielos: $prompt',
      timestamp: DateTime.now(),
    ));

    if (mounted) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
    }
  }

  void _sendPoll() async {
    final question = _pollQuestionCtrl.text.trim();
    if (question.isEmpty) return;

    final options = _optionCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (options.length < 2) return;

    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    final firestore = context.read<OnlineFirestoreService>();

    await firestore.sendMessage(GroupMessageModel(
      id: const Uuid().v4(),
      groupId: widget.group.id,
      senderId: user.id,
      senderName: user.firstName,
      type: 'poll',
      text: '📊 Encuesta: $question',
      payload: {
        'question': question,
        'options': options,
        'votes': <String, dynamic>{}, // option -> list of voterIds
      },
      timestamp: DateTime.now(),
    ));

    if (mounted) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    final icebreakers = [
      '¿Cuál fue el recital o viaje más divertido al que fueron?',
      '¿Qué serie o película vieron más de dos veces?',
      'Si pudieran teletransportarse ahora mismo a un café o bar, ¿a cuál irían?',
      'Dos verdades y una mentira para presentarse al Círculo.',
      '¿Cuál es su comida o lugar favorito de la ciudad?',
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabController,
            labelColor: primary,
            indicatorColor: primary,
            tabs: [
              Tab(
                text: l10n.get('icebreakerBtn'),
                icon: const Icon(Icons.casino_outlined, size: 20),
              ),
              Tab(
                text: l10n.get('createPollBtn'),
                icon: const Icon(Icons.poll_outlined, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pestaña Rompehielos
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: icebreakers.length,
                  itemBuilder: (context, i) {
                    final item = icebreakers[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.chat_bubble_outline_rounded),
                        title: Text(
                          item,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        trailing: const Icon(Icons.send_rounded, size: 18),
                        onTap: () => _sendIcebreaker(item),
                      ),
                    );
                  },
                ),

                // Pestaña Encuesta
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _pollQuestionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Pregunta de la encuesta',
                          hintText: 'Ej: ¿Qué día les queda mejor para merendar?',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_optionCtrls.length, (idx) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            controller: _optionCtrls[idx],
                            decoration: InputDecoration(
                              labelText: 'Opción ${idx + 1}',
                            ),
                          ),
                        );
                      }),
                      if (_optionCtrls.length < 4)
                        TextButton.icon(
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Agregar opción'),
                          onPressed: () {
                            setState(() {
                              _optionCtrls.add(TextEditingController());
                            });
                          },
                        ),
                      const SizedBox(height: 12),
                      LoadingPrimaryButton(
                        label: 'Lanzar Encuesta',
                        onPressed: _sendPoll,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
