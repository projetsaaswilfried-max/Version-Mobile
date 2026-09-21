import 'package:flutter/material.dart';

import '../../../../core/config/legal_urls.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/widgets/legal_link_text.dart';
import '../account/widgets/account_list_widgets.dart';

class LegalPagesPage extends StatelessWidget {
  const LegalPagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mentions légales')),
      body: ListView(
        children: [
          AccountSectionRow(
            label: 'CGU / CGV',
            onTap: () => openLegalUrl(LegalUrls.cgv),
          ),
          AccountSectionRow(
            label: 'Politique de confidentialité',
            onTap: () => openLegalUrl(LegalUrls.privacy),
          ),
          AccountSectionRow(
            label: 'Mentions légales',
            onTap: () => openLegalUrl(LegalUrls.mentions),
          ),
          AccountSectionRow(
            label: 'Charte d\'éthique',
            onTap: () => openLegalUrl(LegalUrls.charter),
          ),
          AccountSectionRow(
            label: 'Normes de sécurité des enfants',
            onTap: () => openLegalUrl(LegalUrls.childSafety),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Agapeo est réservé aux adultes de 18 ans et plus. '
              'Tout contenu impliquant un mineur doit être signalé.',
            ),
          ),
        ],
      ),
    );
  }
}
