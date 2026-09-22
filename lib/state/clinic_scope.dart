import 'package:flutter/material.dart';
import 'clinic_state.dart';

class ClinicScope extends InheritedNotifier<ClinicState> {
  const ClinicScope({
    super.key,
    required ClinicState state,
    required super.child,
  }) : super(notifier: state);

  static ClinicState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ClinicScope>();
    assert(scope != null, 'No ClinicScope found in context');
    return scope!.notifier!;
  }
}

extension ClinicContextExt on BuildContext {
  ClinicState get clinic => ClinicScope.of(this);
}
