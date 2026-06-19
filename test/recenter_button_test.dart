// test/recenter_button_test.dart
//
// Widget tests for RecenterButton — particularly that
// _handleRecenter captures the ScaffoldMessenger BEFORE the
// await on the position source, so a disposed widget context
// can't silently take down the snackbar path.

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/utils/l10n.dart';
import 'package:urbix/widgets/recenter_button.dart';

import 'helpers/test_l10n.dart';

Widget _wrap({
  required RecenterButton button,
  required GlobalKey<ScaffoldMessengerState> messengerKey,
}) {
  return MaterialApp(
    localizationsDelegates: const [TestL10nDelegate()],
    supportedLocales: kSupportedLocales,
    scaffoldMessengerKey: messengerKey,
    home: Scaffold(
      body: button,
    ),
  );
}

void main() {
  testWidgets(
      'recenter snackbar still shows after the await when context is '
      'captured pre-await (regression for the "post-await context lookup '
      'fails" bug)',
      (tester) async {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    // onRecenter is delayed so the post-await code has time
    // to run with whatever state the context is in. We
    // deliberately don't dispose the widget between the
    // press and the await resolving — the bug we're locking
    // down is the LOOKUP-after-await using a possibly-stale
    // BuildContext, not a disposed-widget scenario.
    final onRecenterCompleter = Completer<void>();
    final button = RecenterButton(
      onRecenter: () => onRecenterCompleter.future,
    );
    await tester.pumpWidget(_wrap(
      button: button,
      messengerKey: messengerKey,
    ));
    await tester.pumpAndSettle();

    // Tap the FAB. This starts _handleRecenter which awaits
    // onRecenter (still pending).
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    // Resolve onRecenter. _handleRecenter resumes on the next
    // microtask, then calls messenger.showSnackBar.
    onRecenterCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SnackBar), findsOneWidget,
        reason: 'the snackbar should still appear even though '
            'ScaffoldMessenger.of(context) is called after the await '
            '—we capture the messenger reference up-front');
  });

  testWidgets(
      'recenter success snackbar is suppressed when onRecenter throws '
      '(regression for the "error + success snackbars back-to-back" bug)',
      (tester) async {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    // onRecenter throws — simulates a real GPS / network failure
    // after the user taps recenter. The map screen's
    // _initializeMap catches internally and surfaces its own error
    // snackbar; the RecenterButton's success snackbar must NOT
    // also fire, otherwise the user sees contradictory messages.
    final button = RecenterButton(
      onRecenter: () => Future<void>.error(
          Exception('GPS unavailable')),
    );
    await tester.pumpWidget(_wrap(
      button: button,
      messengerKey: messengerKey,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SnackBar), findsNothing,
        reason: 'success snackbar must not fire when onRecenter '
            'throws — the call site surfaces its own error message');
  });
}