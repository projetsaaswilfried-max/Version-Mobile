import 'package:equatable/equatable.dart';

class PremiumPlan extends Equatable {
  const PremiumPlan({
    required this.label,
    required this.priceLabel,
    required this.recommended,
  });

  final String label;
  final String priceLabel;
  final bool recommended;

  @override
  List<Object?> get props => [label, priceLabel, recommended];
}

const premiumCatalog = <PremiumPlan>[
  PremiumPlan(label: '1 semaine', priceLabel: '2 335 FCFA', recommended: false),
  PremiumPlan(
    label: 'Mi-mois (15 jours)',
    priceLabel: '4 086 FCFA',
    recommended: false,
  ),
  PremiumPlan(label: 'Mensuel', priceLabel: '7 003 FCFA', recommended: false),
  PremiumPlan(
    label: 'Trimestriel',
    priceLabel: '17 507 FCFA',
    recommended: true,
  ),
];
