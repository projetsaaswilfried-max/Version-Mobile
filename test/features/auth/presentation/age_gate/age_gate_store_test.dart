import 'package:agapeo/features/auth/domain/repositories/age_gate_store.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemoryAgeGateStore implements AgeGateStore {
  bool _accepted = false;

  @override
  Future<bool> isAccepted() async => _accepted;

  @override
  Future<void> accept() async {
    _accepted = true;
  }
}

void main() {
  test('accept persists true', () async {
    final store = InMemoryAgeGateStore();
    expect(await store.isAccepted(), false);
    await store.accept();
    expect(await store.isAccepted(), true);
  });
}
