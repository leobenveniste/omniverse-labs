import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/circle_group_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/online_firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_feedback_components.dart';
import '../../l10n/app_localizations.dart';

class CreateGroupPlanSheet extends StatefulWidget {
  final CircleGroupModel group;

  const CreateGroupPlanSheet({super.key, required this.group});

  @override
  State<CreateGroupPlanSheet> createState() => _CreateGroupPlanSheetState();
}

class _CreateGroupPlanSheetState extends State<CreateGroupPlanSheet> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _category = AppPlans.coffee;
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 2, hours: 3));

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      );
      if (pickedTime != null) {
        setState(() {
          _scheduledAt = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _handleSavePlan() async {
    final title = _titleCtrl.text.trim();
    final location = _locationCtrl.text.trim();

    if (title.isEmpty) return;

    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    final firestore = context.read<OnlineFirestoreService>();

    await SavingOverlayHUD.run(
      context,
      message: 'Publicando salida en el grupo...',
      task: () async {
        final planId = const Uuid().v4();
        final plan = GroupPlanModel(
          id: planId,
          groupId: widget.group.id,
          creatorId: user.id,
          creatorName: user.firstName,
          title: title,
          category: _category,
          scheduledAt: _scheduledAt,
          locationName: location,
          rsvpStatus: {user.id: 'going'},
          checkedInUserIds: [],
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        await firestore.upsertPlan(plan);

        // Notificar al chat grupal
        await firestore.sendMessage(GroupMessageModel(
          id: const Uuid().v4(),
          groupId: widget.group.id,
          senderId: user.id,
          senderName: user.firstName,
          type: 'plan',
          text: '📅 ¡${user.firstName} propuso una salida: "$title"!',
          payload: plan.toJson(),
          timestamp: DateTime.now(),
        ));
      },
    );

    if (mounted) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.get('createPlanBtn'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Título de la salida *',
                hintText: 'Ej: Merienda en Colegiales o Tarde de Catan',
                prefixIcon: Icon(Icons.event_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // Selector Categoría
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category_outlined, size: 20),
              ),
              items: AppPlans.all.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(l10n.translatePlan(p)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 16),

            // Fecha y Hora
            InkWell(
              onTap: _selectDateTime,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEE d MMM • HH:mm', l10n.langCode)
                              .format(_scheduledAt),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.calendar_month_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Lugar o barrio',
                hintText: 'Ej: Cuervo Café o Plaza Francia',
                prefixIcon: Icon(Icons.place_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 24),

            LoadingPrimaryButton(
              label: 'Publicar Salida en el Círculo',
              onPressed: _handleSavePlan,
            ),
          ],
        ),
      ),
    );
  }
}
