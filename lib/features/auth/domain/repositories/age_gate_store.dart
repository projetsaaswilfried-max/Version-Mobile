abstract class AgeGateStore {
  Future<bool> isAccepted();

  Future<void> accept();
}
