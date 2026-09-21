/// Centralized asset paths — never hardcode an asset string elsewhere.
class AppAssets {
  const AppAssets._();

  static const _icons = 'assets/icons';
  static const _images = 'assets/images';

  static const logoFull = '$_images/logo_full.png';
  static const logoFullWhite = '$_images/logo_full_white.png';

  static const introSlide1 = '$_images/intro/intro_slide_1.png';
  static const introSlide2 = '$_images/intro/intro_slide_2.png';
  static const introSlide3 = '$_images/intro/intro_slide_3.png';

  static const emptyChat = '$_images/empty/empty_chat.png';
  static const emptyDiscover = '$_images/empty/empty_discover.png';
  static const emptyFeed = '$_images/empty/empty_feed.png';
  static const emptyAccount = '$_images/empty/empty_account.png';

  static const onboardingHeroEssentials =
      '$_images/onboarding/hero_essentials.svg';
  static const onboardingHeroFaith = '$_images/onboarding/hero_faith.svg';
  static const onboardingHeroPhoto = '$_images/onboarding/hero_photo.svg';

  static const icHeart = '$_icons/ic_heart.svg';
  static const icChat = '$_icons/ic_chat.svg';
  static const icProfile = '$_icons/ic_profile.svg';
  static const icDiscover = '$_icons/ic_discover.svg';
  static const icFeed = '$_icons/ic_feed.svg';
  static const icBell = '$_icons/ic_bell.svg';
  static const icGoogle = '$_icons/ic_google.svg';
  static const icSend = '$_icons/ic_send.svg';
  static const icClose = '$_icons/ic_close.svg';
  static const appIcon = 'assets/branding/app_icon.png';
}
