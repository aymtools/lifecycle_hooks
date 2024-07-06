import 'dart:async';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_lifecycle_viewmodel/an_lifecycle_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:weak_collections/weak_collections.dart' as weak;

final Map<BuildContext, LifecycleObserverRegistry> _hooksLifecycleRegistry =
    weak.WeakMap();

class LifecycleHook extends Hook<void> {
  const LifecycleHook();

  @override
  HookState<void, Hook<void>> createState() => _LifecycleHookState();
}

class _LifecycleHookState extends HookState<void, LifecycleHook>
    with LifecycleObserverRegistryDelegateMixin {
  bool _isThis = false;

  @override
  void initHook() {
    var lifecycle = _hooksLifecycleRegistry[context];
    if (lifecycle == null) {
      final ctx = context;
      _isThis = true;
      lifecycle = this;
      _hooksLifecycleRegistry[ctx] = this;
      addLifecycleObserver(LifecycleObserver.eventDestroy(
          () => _hooksLifecycleRegistry.remove(ctx)));
    }

    if (_isThis) {
      lifecycleDelegate.initState();
    }
  }

  @override
  void build(BuildContext context) {
    if (_isThis) {
      lifecycleDelegate.didChangeDependencies();
    }
  }

  @override
  void dispose() {
    if (_isThis) {
      lifecycleDelegate.dispose();
    }
  }
}
//
// class A with ViewModel {
//   late ValueNotifier<int> counter;
//
//   void fetchData() {
//     print('fetchData');
//     counter = ValueNotifier(0);
//   }
//
//   void add() {
//     counter.value++;
//   }
// }
//
// class TestHooks extends HookWidget {
//   const TestHooks({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     A instance = useLifecycleEffect<A>(
//       factory: A.new,
//       launchOnFirstStart: (a) {
//         print('launchOnFirstStarted');
//         a.fetchData();
//       },
//     );
//     useListenable(instance.counter);
//     return const Placeholder();
//   }
// }

LifecycleObserverRegistry useLifecycle() {
  use(const LifecycleHook());
  return _hooksLifecycleRegistry[useContext()]!;
}

typedef Launcher<T> = FutureOr Function(T data);

T useLifecycleEffect<T extends Object>({
  T? data,
  T Function()? factory,
  Launcher<T>? launchOnFirstCreate,
  Launcher<T>? launchOnFirstStart,
  Launcher<T>? launchOnFirstResume,
  Launcher<T>? repeatOnStarted,
  Launcher<T>? repeatOnResumed,
}) {
  final life = useLifecycle();
  return life.withLifecycleEffect(
      data: data,
      factory: factory,
      launchOnFirstCreate: launchOnFirstCreate,
      launchOnFirstStart: launchOnFirstStart,
      launchOnFirstResume: launchOnFirstResume,
      repeatOnStarted: repeatOnStarted,
      repeatOnResumed: repeatOnResumed);
}

T useLifecycleViewModelEffect<T extends ViewModel>({
  T? data,
  T Function()? factory,
  Launcher<T>? launchOnFirstCreate,
  Launcher<T>? launchOnFirstStart,
  Launcher<T>? launchOnFirstResume,
  Launcher<T>? repeatOnStarted,
  Launcher<T>? repeatOnResumed,
}) {
  use(const LifecycleHook());
  final life = _hooksLifecycleRegistry[useContext()];
  return life!.withLifecycleEffect(
      data: data,
      factory: factory ?? life.viewModels(),
      launchOnFirstCreate: launchOnFirstCreate,
      launchOnFirstStart: launchOnFirstStart,
      launchOnFirstResume: launchOnFirstResume,
      repeatOnStarted: repeatOnStarted,
      repeatOnResumed: repeatOnResumed);
}
