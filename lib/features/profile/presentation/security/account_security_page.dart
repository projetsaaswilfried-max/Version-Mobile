import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../support/presentation/support_list_page.dart';
import '../account/widgets/account_list_widgets.dart';
import 'blocked_accounts_page.dart';
import 'change_email_page.dart';
import 'change_password_page.dart';
import 'delete_account_page.dart';
import 'export_data_page.dart';
import 'legal_pages_page.dart';
import 'add_profile_photo_page.dart';
import 'photos_management_page.dart';

class AccountSecurityPage extends StatelessWidget {
  const AccountSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compte & Sécurité')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.lg,
        ),
        child: Column(
          children: [
            AppSettingsGroup(
              title: 'Compte',
              children: [
                AccountSectionRow(
                  label: 'Vérification',
                  icon: Icons.verified_outlined,
                  onTap: () => Navigator.of(context).push(
                    // Photo puis selfie, toujours dans cet ordre (D34) -
                    // même règle que le bandeau et Découvrir, y compris
                    // depuis ce point d'entrée peu visible des réglages.
                    MaterialPageRoute<void>(
                      builder: (_) => const AddProfilePhotoPage(),
                    ),
                  ),
                ),
                AccountSectionRow(
                  label: 'Changer l\'email',
                  icon: Icons.mail_outline,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChangeEmailPage(),
                    ),
                  ),
                ),
                AccountSectionRow(
                  label: 'Changer le mot de passe',
                  icon: Icons.password_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChangePasswordPage(),
                    ),
                  ),
                ),
                AccountSectionRow(
                  label: 'Gérer mes photos',
                  icon: Icons.photo_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PhotosManagementPage(),
                    ),
                  ),
                ),
                AccountSectionRow(
                  label: 'Export des données',
                  icon: Icons.download_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ExportDataPage(),
                    ),
                  ),
                ),
              ],
            ),
            AppSettingsGroup(
              title: 'Aide',
              children: [
                AccountSectionRow(
                  label: 'Support',
                  icon: Icons.headset_mic_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SupportListPage(),
                    ),
                  ),
                ),
                AccountSectionRow(
                  label: 'Mentions légales',
                  icon: Icons.description_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LegalPagesPage(),
                    ),
                  ),
                ),
              ],
            ),
            AppSettingsGroup(
              title: 'Sécurité',
              children: [
                AccountSectionRow(
                  label: 'Comptes bloqués',
                  icon: Icons.block_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BlockedAccountsPage(),
                    ),
                  ),
                ),
                AccountSectionRow(
                  label: 'Supprimer mon compte',
                  icon: Icons.delete_outline,
                  danger: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DeleteAccountPage(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
