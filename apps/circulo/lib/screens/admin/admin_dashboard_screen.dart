import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/billing_service.dart';
import '../../services/online_firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final billing = context.watch<BillingService>();
    final firestore = context.watch<OnlineFirestoreService>();
    final primary = AppTheme.primaryColor(context);

    if (auth.currentUser?.isSuperAdmin != true) {
      return const Scaffold(
        body: Center(child: Text('Acceso restringido para Administradores.')),
      );
    }

    final users = firestore.currentUsers;
    final groups = firestore.currentGroups;
    final reports = firestore.getReports();

    return AppScaffold(
      showHelpButton: false,
      title: 'Panel Superadmin',
      subtitle: 'Omniverse Labs • Gestión Online',
      body: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            labelColor: primary,
            indicatorColor: primary,
            tabs: [
              Tab(text: 'Usuarios (${users.length})'),
              Tab(text: 'Grupos (${groups.length})'),
              const Tab(text: 'Monetización & Sandbox'),
              Tab(text: 'Reportes (${reports.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // PESTAÑA 1: USUARIOS
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final u = users[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(u.firstName.isNotEmpty
                              ? u.firstName[0].toUpperCase()
                              : '?'),
                        ),
                        title: Text(
                          '${u.fullName} ${u.isSuperAdmin ? "⭐" : ""}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${u.email}\n${GroupRoles.getIcon(u.groupRole)} ${u.region} • ${u.totalMeetupsCount} salidas',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_calendar_rounded),
                          tooltip: 'Ajustar asistencias reales',
                          onPressed: () => _editManualMeetups(context, u, auth),
                        ),
                      ),
                    );
                  },
                ),

                // PESTAÑA 2: GRUPOS
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(g.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          'Estado: ${g.status} • ${g.memberIds.length}/${g.maxMembers} miembros\nRegión: ${g.region}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          g.isForming ? 'En formación' : 'Activo',
                          style: TextStyle(
                            color: g.isForming
                                ? AppTheme.warmAmber
                                : AppTheme.emeraldMint,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // PESTAÑA 3: MONETIZACIÓN & SANDBOX
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: SwitchListTile(
                        title: const Text(
                          'Modo Sandbox Activo',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Permite probar compras y suscripciones sin conectarse a Google Play Console real.',
                        ),
                        value: billing.isSandboxMode,
                        onChanged: (val) => billing.setSandboxMode(val),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Simulación para Usuario Actual',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Plus Activo: ${auth.currentUser?.isPlusMember == true ? "SÍ ⭐" : "NO"}',
                            ),
                            Text(
                              'Swipes Restantes Hoy: ${auth.currentUser?.dailySwipesRemaining ?? 0}',
                            ),
                            Text(
                              'Boosts Disponibles: ${auth.currentUser?.remainingBoosts ?? 0}',
                            ),
                            Text(
                              'Super-Ondas Disponibles: ${auth.currentUser?.remainingSuperOndas ?? 0}',
                            ),
                            const Divider(height: 24),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    final cur = auth.currentUser;
                                    if (cur != null) {
                                      final updated = cur.copyWith(
                                        isPlusActive: !cur.isPlusActive,
                                      );
                                      await firestore.upsertUser(updated);
                                      await auth.refreshCurrentUser();
                                    }
                                  },
                                  child: const Text('Alternar Círculo Plus'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final cur = auth.currentUser;
                                    if (cur != null) {
                                      final updated = cur.copyWith(
                                        dailySwipesRemaining: 30,
                                        totalSwipesCounter: 0,
                                      );
                                      await firestore.upsertUser(updated);
                                      await auth.refreshCurrentUser();
                                    }
                                  },
                                  child: const Text('Resetear Swipes a 30'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final cur = auth.currentUser;
                                    if (cur != null) {
                                      final updated = cur.copyWith(
                                        remainingBoosts:
                                            cur.remainingBoosts + 5,
                                        remainingSuperOndas:
                                            cur.remainingSuperOndas + 5,
                                      );
                                      await firestore.upsertUser(updated);
                                      await auth.refreshCurrentUser();
                                    }
                                  },
                                  child: const Text('+5 Boosts & +5 Ondas'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // PESTAÑA 4: REPORTES
                reports.isEmpty
                    ? const Center(child: Text('No hay reportes pendientes.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: reports.length,
                        itemBuilder: (context, i) {
                          final r = reports[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const Icon(Icons.report_problem_rounded,
                                  color: AppTheme.errorRed),
                              title: Text(r.reason),
                              subtitle: Text(
                                'Reportado: ${r.reportedUserId}\nPor: ${r.reporterUserId}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editManualMeetups(
      BuildContext context, UserModel user, AuthService auth) {
    final ctrl =
        TextEditingController(text: (user.manualMeetupCount ?? 0).toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajuste de Salidas: ${user.firstName}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Asistencias manuales acreditadas',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final count = int.tryParse(ctrl.text.trim());
              await auth.updateUserManualMeetups(user.id, count);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
