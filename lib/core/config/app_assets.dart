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

  static const icHeart = '$_icons/ic_heart.svg';
  static const icChat = '$_icons/ic_chat.svg';
  static const icProfile = '$_icons/ic_profile.svg';
  static const icDiscover = '$_icons/ic_discover.svg';
  static const icFeed = '$_icons/ic_feed.svg';
  static const icGoogle = '$_icons/ic_google.svg';
}
