import 'package:flutter/widgets.dart';

/// Global route observer for the app's navigator.
///
/// STEP-55.11: feature screens that stay mounted beneath a route-hosted sheet
/// (the attendance list under its batch form, for example) need a resume hook
/// to reload data the sheet persisted. `RouteAware.didPopNext` fires when such
/// a sheet pops back to the list, without the list having to poll the
/// repository or re-create its bloc.
///
/// Wired in `lib/app/app.dart` via `MaterialApp.router`'s `navigatorObservers`
/// (go_router surfaces its internal navigator's observers through
/// `GoRouter.observers` on the router config).
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
