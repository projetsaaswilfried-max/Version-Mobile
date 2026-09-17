import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeShellController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final homeShellIndexProvider =
    NotifierProvider.autoDispose<HomeShellController, int>(
      HomeShellController.new,
    );
