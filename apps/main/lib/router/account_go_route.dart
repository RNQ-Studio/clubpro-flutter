import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Route-local forms and imperative loads belong to the account that opened
/// them, just like provider data. Reset below the global Navigator so its key
/// cannot reparent an earlier account's editor into the next account's session.
class AccountGoRoute extends GoRoute {
  AccountGoRoute({
    required super.path,
    super.name,
    GoRouterWidgetBuilder? builder,
    super.parentNavigatorKey,
    super.redirect,
    super.onExit,
    super.caseSensitive,
    super.routes,
  }) : super(
          builder: builder == null
              ? null
              : (context, state) => _AccountRouteBoundary(
                    child: builder(context, state),
                  ),
        );
}

class _AccountRouteBoundary extends ConsumerStatefulWidget {
  const _AccountRouteBoundary({required this.child});
  final Widget child;

  @override
  ConsumerState<_AccountRouteBoundary> createState() =>
      _AccountRouteBoundaryState();
}

class _AccountRouteBoundaryState extends ConsumerState<_AccountRouteBoundary> {
  String? _accountId;
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth is AuthAuthenticated) {
      if (_accountId != null && _accountId != auth.user.id) _generation++;
      _accountId = auth.user.id;
    } else if (auth is! AuthLoading) {
      if (_accountId != null) _generation++;
      _accountId = null;
    }
    // AuthLoading can be a refresh for this same account. Its existing route
    // state and safe return destination survive; a different ID never does.
    // Adopting the initial restored identity must retain the session-check
    // screen's refresh listener, including hosts that embed the router alone.
    return KeyedSubtree(key: ValueKey(_generation), child: widget.child);
  }
}
