import 'dart:async';
import 'dart:collection';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_lifecycle_viewmodel/an_lifecycle_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:weak_collections/weak_collections.dart' as weak;

final Map<BuildContext, _HookLifecycleRegistry> _hooksLifecycleRegistry =
    weak.WeakMap();

class _HookLifecycleRegistry {
  final Element Function() contextProvider;
  late final LifecycleObserverRegistryDelegate registry;

  _HookLifecycleRegistry(this.contextProvider) {
    registry = LifecycleObserverRegistryDelegate(
        target: registry, contextProvider: contextProvider);
  }

  LinkedList<_LEntry>? _hooks;

  _LifecycleHookState? get firstOrNullHook =>
      _hooks == null || _hooks!.isEmpty ? null : _hooks!.first.value;

  _LifecycleHookState? get lastOrNullHook =>
      _hooks == null || _hooks!.isEmpty ? null : _hooks!.last.value;
}

class _LEntry extends LinkedListEntry<_LEntry> {
  _LEntry(this.value);

  _LifecycleHookState value;
}

class LifecycleHook extends Hook<void> {
  const LifecycleHook();

  @override
  HookState<void, Hook<void>> createState() => _LifecycleHookState();
}

class _LifecycleHookState extends HookState<void, LifecycleHook> {
  BuildContext? _ctx;

  @override
  void initHook() {
    var hookLifecycle = _hooksLifecycleRegistry[context];

    if (hookLifecycle == null) {
      final ctx = context;
      _ctx = context;
      hookLifecycle = _HookLifecycleRegistry(() => _ctx as Element);
      _hooksLifecycleRegistry[ctx] = hookLifecycle;
      hookLifecycle.registry.addLifecycleObserver(
          LifecycleObserver.eventDestroy(
              () => _hooksLifecycleRegistry.remove(ctx)));
    }
    hookLifecycle._hooks ??= LinkedList();
    hookLifecycle._hooks!.add(_LEntry(this));

    if (hookLifecycle.firstOrNullHook == this) {
      hookLifecycle.registry.initState();
    }
  }

  @override
  void build(BuildContext context) {
    var hookLifecycle = _hooksLifecycleRegistry[context];
    _ctx = context;

    if (hookLifecycle?.firstOrNullHook == this) {
      hookLifecycle!.registry.didChangeDependencies();
    }
  }

  @override
  void dispose() {
    if (_ctx == null) return;

    ///等待最后一个hook销毁时 销毁lifecycle
    var hookLifecycle = _hooksLifecycleRegistry[_ctx];
    if (hookLifecycle?.lastOrNullHook == this) {
      hookLifecycle!.registry.dispose();
    }
    _ctx = null;
  }
}

LifecycleObserverRegistry useLifecycle() {
  use(const LifecycleHook());
  return _hooksLifecycleRegistry[useContext()]!.registry;
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
  LifecycleEffectTask<T>? launchOnDestroy,
  LifecycleEffectTask<T>? repeatOnStarted,
  LifecycleEffectTask<T>? repeatOnResumed,
}) {
  final life = useLifecycle();

  return life.withLifecycleEffect(
    factory: () => life.lifecycleExtData.putIfAbsent(
        TypedKey<T>(useLifecycleEffect),
        () => data ?? factory?.call() ?? factory2!.call(life)),
    launchOnFirstCreate: _convertLifecycleEffectTask(life, launchOnFirstCreate),
    launchOnFirstStart: _convertLifecycleEffectTask(life, launchOnFirstStart),
    launchOnFirstResume: _convertLifecycleEffectTask(life, launchOnFirstResume),
    launchOnDestroy: _convertLifecycleEffectTask(life, launchOnDestroy),
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
  LifecycleEffectTask<VM>? launchOnDestroy,
  LifecycleEffectTask<VM>? repeatOnStarted,
  LifecycleEffectTask<VM>? repeatOnResumed,
}) {
  final life = useLifecycle();
  VM Function()? vmFactory;
  if (data != null) {
    vmFactory = () => data;
  }
  if (vmFactory == null && factory != null) {
    vmFactory = factory;
  }
  if (vmFactory == null && factory2 != null) {
    vmFactory = () => factory2(life);
  }

  return life.withLifecycleEffect(
    factory: () => life.lifecycleExtData.putIfAbsent(
        TypedKey<VM>(useLifecycleViewModelEffect),
        () => life.viewModels(factory: vmFactory)),
    launchOnFirstCreate: _convertLifecycleEffectTask(life, launchOnFirstCreate),
    launchOnFirstStart: _convertLifecycleEffectTask(life, launchOnFirstStart),
    launchOnFirstResume: _convertLifecycleEffectTask(life, launchOnFirstResume),
    launchOnDestroy: _convertLifecycleEffectTask(life, launchOnDestroy),
    repeatOnStarted: _convertLifecycleEffectTask(life, repeatOnStarted),
    repeatOnResumed: _convertLifecycleEffectTask(life, repeatOnResumed),
  );
}

FutureOr Function(T data)? _convertLifecycleEffectTask<T>(
        LifecycleObserverRegistry lifecycle,
        FutureOr Function(LifecycleObserverRegistry, T)? callback) =>
    callback == null ? null : (data) => callback(lifecycle, data);
