import 'package:equatable/equatable.dart';

class PremiumPlan extends Equatable {
  const PremiumPlan({
    required this.code,
    required this.label,
    required this.priceLabel,
    required this.recommended,
  });

  /// Valeur attendue par la fonction Supabase `mobile-payment-handoff`
  /// (`WEEKLY` / `HALF_MONTH` / `MONTHLY` / `QUARTERLY`).
  final String code;
  final String label;
  final String priceLabel;
  final bool recommended;

  @override
  List<Object?> get props => [code, label, priceLabel, recommended];
}

const premiumCatalog = <PremiumPlan>[
  PremiumPlan(
    code: 'WEEKLY',
    label: '1 semaine',
    priceLabel: '2 335 FCFA',
    recommended: false,
  ),
  PremiumPlan(
    code: 'HALF_MONTH',
    label: 'Mi-mois (15 jours)',
    priceLabel: '4 086 FCFA',
    recommended: false,
  ),
  PremiumPlan(
    code: 'MONTHLY',
    label: 'Mensuel',
    priceLabel: '7 003 FCFA',
    recommended: false,
  ),
  PremiumPlan(
    code: 'QUARTERLY',
    label: 'Trimestriel',
    priceLabel: '17 507 FCFA',
    recommended: true,
  ),
];
