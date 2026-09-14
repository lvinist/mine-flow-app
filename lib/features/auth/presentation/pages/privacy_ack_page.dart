import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

class PrivacyAckPage extends StatelessWidget {
  const PrivacyAckPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return FScaffold(
      header: FHeader(
        title: Text(l10n.privacyTitle),
        suffixes: [
          FButton(
            variant: FButtonVariant.ghost,
            onPress: () async {
              await context.read<AuthCubit>().signOut();
            },
            child: Text(l10n.privacyLogout),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: FCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.privacyCardTitle,
                      style: theme.typography.display.sm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.privacyCardSubtitle,
                      style: theme.typography.body.md.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(l10n.privacyCardBody, style: theme.typography.body.md),
                    const SizedBox(height: 32),
                    FButton(
                      onPress: () {
                        // Mark version 1 as acknowledged
                        context.read<SettingsCubit>().updatePrivacyAckVersion(
                          1,
                        );
                        context.go(AppRoutes.dashboard);
                      },
                      child: Text(l10n.privacyAckButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
