enum ProfileHubSection {
  profile,
  faith,
  moreInfo,
  plan,
  posts,
  favorites,
  interested,
  privacy,
  account;

  String get label => switch (this) {
    ProfileHubSection.profile => 'Mon Profil',
    ProfileHubSection.faith => 'Ma Foi',
    ProfileHubSection.moreInfo => 'Plus d\'infos',
    ProfileHubSection.plan => 'Mon Plan',
    ProfileHubSection.posts => 'Mes Publications',
    ProfileHubSection.favorites => 'Mes Favoris',
    ProfileHubSection.interested => 'Qui s\'intéresse à moi',
    ProfileHubSection.privacy => 'Confidentialité',
    ProfileHubSection.account => 'Compte & Sécurité',
  };
}
