class DiscoverPremiumPlan {
  const DiscoverPremiumPlan({required this.label, required this.priceLabel});

  final String label;
  final String priceLabel;
}

/// Formules PRD §11 (affichage D04 ; paiement = P01).
const discoverPremiumPlans = <DiscoverPremiumPlan>[
  DiscoverPremiumPlan(label: '1 semaine', priceLabel: '2 335 FCFA'),
  DiscoverPremiumPlan(label: 'Mi-mois (15 jours)', priceLabel: '4 086 FCFA'),
  DiscoverPremiumPlan(label: 'Mensuel', priceLabel: '7 003 FCFA'),
  DiscoverPremiumPlan(label: 'Trimestriel', priceLabel: '17 507 FCFA'),
];
