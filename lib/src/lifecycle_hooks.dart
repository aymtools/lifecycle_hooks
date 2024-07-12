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

LifecycleObserverRegistry useLifecycle() {
  use(const LifecycleHook());
  return _hooksLifecycleRegistry[useContext()]!;
}

typedef LifecycleEffectTask<T> = FutureOr Function(
    LifecycleObserverRegistry lifecycle, T data);

T useLifecycleEffect<T extends Object>({
  T? data,
  T Function()? factory,
  T Function(LifecycleObserverRegistry lifecycle)? factory2,
  LifecycleEffectTask<T>? launchOnFirstCreate,
  LifecycleEffectTask<T>? launchOnFirstStart,
  LifecycleEffectTask<T>? launchOnFirstResume,
  LifecycleEffectTask<T>? repeatOnStarted,
  LifecycleEffectTask<T>? repeatOnResumed,
}) {
  final life = useLifecycle();

  return life.withLifecycleEffect(
    factory: () => life.lifecycleExtData.putIfAbsent(
        TypedKey<T>('useLifecycleEffect'),
        () => data ?? factory?.call() ?? factory2!.call(life)),
    launchOnFirstCreate: _convertLifecycleEffectTask(life, launchOnFirstCreate),
    launchOnFirstStart: _convertLifecycleEffectTask(life, launchOnFirstStart),
    launchOnFirstResume: _convertLifecycleEffectTask(life, launchOnFirstResume),
    repeatOnStarted: _convertLifecycleEffectTask(life, repeatOnStarted),
    repeatOnResumed: _convertLifecycleEffectTask(life, repeatOnResumed),
  );
}

VM useLifecycleViewModelEffect<VM extends ViewModel>({
  VM? data,
  VM Function()? factory,
  VM Function(LifecycleObserverRegistry lifecycle)? factory2,
  LifecycleEffectTask<VM>? launchOnFirstCreate,
  LifecycleEffectTask<VM>? launchOnFirstStart,
  LifecycleEffectTask<VM>? launchOnFirstResume,
  LifecycleEffectTask<VM>? repeatOnStarted,
  LifecycleEffectTask<VM>? repeatOnResumed,
}) {
  final life = useLifecycle();

  return life.withLifecycleEffect(
    factory: () => life.lifecycleExtData.putIfAbsent(
        TypedKey<VM>('useLifecycleViewModelEffect'),
        () =>
            data ??
            factory?.call() ??
            factory2?.call(life) ??
            life.viewModels()),
    launchOnFirstCreate: _convertLifecycleEffectTask(life, launchOnFirstCreate),
    launchOnFirstStart: _convertLifecycleEffectTask(life, launchOnFirstStart),
    launchOnFirstResume: _convertLifecycleEffectTask(life, launchOnFirstResume),
    repeatOnStarted: _convertLifecycleEffectTask(life, repeatOnStarted),
    repeatOnResumed: _convertLifecycleEffectTask(life, repeatOnResumed),
  );
}

FutureOr Function(T data)? _convertLifecycleEffectTask<T>(
        LifecycleObserverRegistry lifecycle,
        FutureOr Function(LifecycleObserverRegistry, T)? callback) =>
    callback == null ? null : (data) => callback(lifecycle, data);
