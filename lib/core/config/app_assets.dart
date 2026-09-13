/// Centralized asset paths — never hardcode an asset string elsewhere.
class AppAssets {
  const AppAssets._();

  static const _icons = 'assets/icons';
  static const _images = 'assets/images';

  static const logoMark = '$_images/logo_mark.svg';
  static const logoFull = '$_images/logo_full.svg';

  static const icHeart = '$_icons/ic_heart.svg';
  static const icChat = '$_icons/ic_chat.svg';
  static const icProfile = '$_icons/ic_profile.svg';
  static const icDiscover = '$_icons/ic_discover.svg';
  static const icFeed = '$_icons/ic_feed.svg';
}
