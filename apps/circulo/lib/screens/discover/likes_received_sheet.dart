import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/online_firestore_service.dart';
import '../../widgets/motion_components.dart';
import '../shop/paywall_bottom_sheet.dart';

class LikesReceivedSheet extends StatelessWidget {
  const LikesReceivedSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LikesReceivedSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();
    final firestore = context.watch<OnlineFirestoreService>();
    final currentUser = authService.currentUser;

    final isPlus = currentUser?.isPlusMember ?? false;
    final cardBg = isDark ? const Color(0xFF1E1B2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);

    // Obtener candidatos que dieron like
    final likerIds = currentUser?.whoLikedMeUserIds ?? [];
    final likers = <UserModel>[];
    for (final id in likerIds) {
      final u = firestore.currentUsers.firstWhere(
        (user) => user.id == id,
        orElse: () => UserModel(
          id: id,
          email: '',
          passwordHash: '',
          firstName: 'Amigo',
          lastName: '',
          birthDate: DateTime(1998, 1, 1),
          duoInviteCode: '',
          createdAt: DateTime.now(),
        ),
      );
      likers.add(u);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Barra de agarre
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.get('whoLikedMeTitle'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '${likers.length} personas quieren armar círculo con vos',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // Contenido principal: Grid de likes
          Expanded(
            child: likers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🌊', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'Aún no tenés likes pendientes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '¡Seguí deslizando en Descubrir o usá un Boost para destacar tu perfil!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      // Grid de perfiles
                      GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: likers.length,
                        itemBuilder: (context, index) {
                          final liker = likers[index];
                          return _buildLikerCard(
                            context,
                            liker,
                            isPlus,
                            isDark,
                            textPrimary,
                          );
                        },
                      ),

                      // Overlay Blur si el usuario NO es Plus
                      if (!isPlus)
                        Positioned.fill(
                          child: ClipRRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.35),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.lock_rounded,
                                        color: Color(0xFF1E1B4B),
                                        size: 36,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '¡${likers.length} personas te dieron Like!',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.get('whoLikedMeLocked'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    PressableScale(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        PaywallBottomSheet.show(
                                          context,
                                          trigger: PaywallTrigger.whoLikedMe,
                                        );
                                      },
                                      child: Container(
                                        height: 48,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFBBF24),
                                              Color(0xFFF59E0B),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFF59E0B)
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          l10n.get('getPlusBtn'),
                                          style: const TextStyle(
                                            color: Color(0xFF1E1B4B),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikerCard(
    BuildContext context,
    UserModel liker,
    bool isPlus,
    bool isDark,
    Color textPrimary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27233A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: Container(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                alignment: Alignment.center,
                child: Text(
                  liker.firstName.isNotEmpty ? liker.firstName[0] : '?',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPlus ? '${liker.firstName}, ${liker.age}' : 'Candidato/a',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
                Text(
                  liker.neighborhood.isNotEmpty
                      ? liker.neighborhood
                      : liker.region,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
