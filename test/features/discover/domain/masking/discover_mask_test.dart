import 'package:agapeo/features/discover/domain/masking/discover_mask.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('masks identity with two characters then asterisks', () {
    expect(maskIdentity('Léa'), 'Lé****');
    expect(maskIdentity('Jean'), 'Je****');
  });

  test('empty identity becomes two asterisks', () {
    expect(maskIdentity(''), '**');
  });

  test('does not reveal card identity when not verified', () {
    expect(revealCardIdentity(visitorVerified: false), isFalse);
  });

  test('reveals when visitor is verified', () {
    expect(revealCardIdentity(visitorVerified: true), isTrue);
  });
}
