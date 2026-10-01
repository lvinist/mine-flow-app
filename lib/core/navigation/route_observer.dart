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
///
/// STEP-55.11 RESIDUAL-2 (B2): the type parameter is `PageRoute<void>`, NOT
/// `ModalRoute<void>`. `RouteObserver.didPush` only forwards `didPushNext`
/// when both the incoming and previous routes are of its type parameter `R`.
/// A Material `DropdownButtonFormField` opens a `_DropdownRoute`, and
/// `showDialog`/popovers open other `PopupRoute`s — all of which are
/// `ModalRoute`s. With `R = ModalRoute<void>` those popups matched, fired
/// `didPushNext` on a still-mounted dirty sheet, and raised the
/// non-dismissible discard dialog ON TOP of the popup (blocking the inventory
/// category dropdown on both platforms). Popups are `PopupRoute`, which does
/// NOT extend `PageRoute`, so narrowing `R` to `PageRoute<void>` makes them
/// invisible to the page-navigation guard while real page-to-page
/// transitions (the 55.5/55.6 list-refresh `didPopNext` contract) still fire.
///
/// NOTE: every `subscribe(this, route)` call site must guard with
/// `route is PageRoute<void>` — `RouteObserver.subscribe` takes an `R` and the
/// `ModalRoute.of(context)` a sheet or list is hosted on is only statically a
/// `ModalRoute`; passing a non-`PageRoute` would be a type error at runtime.
final RouteObserver<PageRoute<void>> routeObserver =
    RouteObserver<PageRoute<void>>();
