import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state.user;
    _nameController = TextEditingController(text: user?.name ?? 'Pengguna');
    _roleController = TextEditingController(text: user?.role ?? 'foreman');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return FScaffold(
      header: FHeader.nested(
        title: Text(l10n.profileEditTitle),
        prefixes: [
          FButton(
            variant: FButtonVariant.ghost,
            onPress: () => context.pop(),
            child: const Icon(LucideIcons.arrowLeft, size: 20),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profileDetail,
                          style: theme.typography.display.xs.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FTextField(
                          control: FTextFieldControl.managed(
                            controller: _nameController,
                          ),
                          label: Text(l10n.profileDisplayName),
                        ),
                        const SizedBox(height: 16),
                        FTextField(
                          control: FTextFieldControl.managed(
                            controller: _roleController,
                          ),
                          label: Text(l10n.profileRoleManaged),
                          enabled: false, // Server-managed
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                BlocConsumer<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state.errorMessage != null) {
                      // Handled below in build
                    }
                  },
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: FAlert(
                              title: Text(l10n.error),
                              subtitle: Text(state.errorMessage!),
                            ),
                          ),
                        FButton(
                          onPress: state.isSubmitting
                              ? null
                              : () async {
                                  await context.read<AuthCubit>().updateProfile(
                                    name: _nameController.text,
                                  );
                                  if (context.mounted &&
                                      context
                                              .read<AuthCubit>()
                                              .state
                                              .errorMessage ==
                                          null) {
                                    context.pop();
                                  }
                                },
                          child: Text(
                            state.isSubmitting
                                ? 'Menyimpan...'
                                : l10n.profileSave,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
