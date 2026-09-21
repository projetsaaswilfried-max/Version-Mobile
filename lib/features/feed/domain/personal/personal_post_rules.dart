import '../../../../core/error/failure.dart';
import '../entities/personal_post_media.dart';

class PersonalPostRules {
  const PersonalPostRules._();

  static const maxChars = 600;
  static const maxImageBytes = 15 * 1024 * 1024;

  static ValidationFailure? validate({
    required String body,
    PersonalPostMedia? media,
  }) {
    final trimmed = body.trim();
    if (trimmed.length > maxChars) {
      return const ValidationFailure('600 caractères maximum.');
    }
    if (trimmed.isEmpty && media == null) {
      return const ValidationFailure('Écris un texte ou ajoute un média.');
    }
    if (media != null && !media.isVideo && media.byteSize > maxImageBytes) {
      return const ValidationFailure('Image trop lourde (15 Mo max).');
    }
    return null;
  }
}
