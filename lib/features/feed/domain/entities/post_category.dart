enum PostCategory {
  teaching,
  testimony,
  workshop,
  advice,
  announcement,
  quote,
  verse,
  news;

  String get label => switch (this) {
    teaching => 'Enseignements',
    testimony => 'Témoignages',
    workshop => 'Atelier/Mariage',
    advice => 'Conseils & Préparation',
    announcement => 'Annonce',
    quote => 'Pensées & Citations',
    verse => 'Verset',
    news => 'Nouveauté',
  };

  String get cardLabel => switch (this) {
    teaching => 'Enseignement',
    testimony => 'Témoignage',
    workshop => 'Atelier/Mariage',
    advice => 'Conseil',
    announcement => 'Annonce',
    quote => 'Citation',
    verse => 'Verset',
    news => 'Nouveauté',
  };
}
