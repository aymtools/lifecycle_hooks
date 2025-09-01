import 'dart:async';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:weak_collections/weak_collections.dart';

@Deprecated('will remove use HookWidget')
typedef LHookWidget = HookWidget;

@Deprecated('will remove use StatefulHookWidget')
typedef LStatefulHookWidget = StatefulHookWidget;

final Map<BuildContext, _HookLifecycleRegistry> _hooksLifecycleRegistry =
    WeakHashMap();

class _HookLifecycleRegistry with LifecycleRegistryDelegateMixin {
  Element Function() contextProvider;

  _HookLifecycleRegistry(this.contextProvider);

  final List<_LifecycleHookState> _hooks = [];

  _LifecycleHookState? get firstOrNullHook =>
      _hooks.isEmpty ? null : _hooks.first;

  _LifecycleHookState? get lastOrNullHook =>
      _hooks.isEmpty ? null : _hooks.last;

  @override
  BuildContext get context => contextProvider();

  void initState() {
    lifecycleDelegate.initState();
  }

  void didChangeDependencies() {
    lifecycleDelegate.didChangeDependencies();
  }

  void dispose() {
    lifecycleDelegate.dispose();
  }
}

//
@Deprecated('will remove')
typedef LifecycleHook = _LifecycleRegistryHook;

///  将hook的内容转换为lifecycle
class _LifecycleRegistryHook extends Hook<void> {
  const _LifecycleRegistryHook();

  @override
  HookState<void, Hook<void>> createState() => _LifecycleHookState();
}

class _LifecycleHookState extends HookState<void, _LifecycleRegistryHook> {
  BuildContext? _ctx;

  @override
  void initHook() {
    var hookLifecycle = _hooksLifecycleRegistry[context];

    if (hookLifecycle == null) {
      final ctx = context;
      _ctx = ctx;
      hookLifecycle = _HookLifecycleRegistry(() => ctx as Element);
      _hooksLifecycleRegistry[ctx] = hookLifecycle;
    }

    hookLifecycle._hooks.add(this);

    if (hookLifecycle.firstOrNullHook == this) {
      hookLifecycle.initState();
    }
  }

  @override
  void build(BuildContext context) {
    var hookLifecycle = _hooksLifecycleRegistry[context];
    _ctx = context;

    if (hookLifecycle?.firstOrNullHook == this) {
      hookLifecycle?.didChangeDependencies();
    }
  }

  @override
  void dispose() {
    if (_ctx == null) return;

    ///等待最后一个hook销毁时 销毁lifecycle
    var hookLifecycle = _hooksLifecycleRegistry[_ctx];
    hookLifecycle?._hooks.remove(this);
    if (hookLifecycle?.lastOrNullHook == this) {
      hookLifecycle!.dispose();
      _hooksLifecycleRegistry.remove(_ctx);
    }
    _ctx = null;
  }
}

/// 使用lifecycleRegistry相关
/// 调用多次时 返回同一个
@Deprecated('will remove')
ILifecycleRegistry useLifecycleRegistry() {
  final context = useContext();
  if (context is ILifecycleRegistry) {
    return context as ILifecycleRegistry;
  } else if (context is StatefulElement &&
      context.state is ILifecycleRegistry) {
    return (context.state as ILifecycleRegistry);
  }
  use(const _LifecycleRegistryHook());
  return _hooksLifecycleRegistry[context]!;
}

/// 使用lifecycle相关
/// 调用多次时 返回同一个
@Deprecated('use Lifecycle.of(useContext())')
Lifecycle useLifecycle() {
  final context = useContext();
  return Lifecycle.of(context);
}

typedef LifecycleEffectTask<T> = FutureOr Function(Lifecycle lifecycle, T data);

final _keyLifecycleEffect = Object();

/// 对于某个对象及其 Type 在生命周期事件中执行
/// 取当前 lifecycle 环境中 Type 唯一的对象 与 其他的 hook 中的 use不同
/// 调用多次时 返回同一个（第一次创建的那一个）
/// 将会抬高 改对象的引用 直到 lifecycle 的销毁时
@Deprecated(
    'use context.withLifecycleEffect() or context.withLifecycleAndDataEffect()')
T useLifecycleEffect<T extends Object>({
  T? data,
  T Function()? factory,
  T Function(Lifecycle lifecycle)? factory2,
  LifecycleEffectTask<T>? launchOnFirstCreate,
  LifecycleEffectTask<T>? launchOnFirstStart,
  LifecycleEffectTask<T>? launchOnFirstResume,
  LifecycleEffectTask<T>? launchOnDestroy,
  LifecycleEffectTask<T>? repeatOnStarted,
  LifecycleEffectTask<T>? repeatOnResumed,
  Object? key,
}) {
  assert(data != null || factory != null || factory2 != null,
      'data and factory and factory2 cannot be null at the same time');
  if (factory2 == null) {
    if (factory != null) {
      factory2 = (_) => factory();
    }
    if (data != null) {
      factory2 = (_) => data;
    }
  }

  return useContext().withLifecycleAndDataEffect(
    factory2: (l) =>
        l.extData.getOrPut<T>(key: _keyLifecycleEffect, ifAbsent: factory2!),
    key: key,
    launchOnFirstCreate: launchOnFirstCreate,
    launchOnFirstStart: launchOnFirstStart,
    launchOnFirstResume: launchOnFirstResume,
    launchOnDestroy: launchOnDestroy,
    repeatOnStarted: repeatOnStarted,
    repeatOnResumed: repeatOnResumed,
  );
}

/// 对于 ViewModel 在当前生命周期事件中执行
/// 取当前 环境中唯一的 ViewModel 对象 与 其他的 hook 中的 use 不同
/// 注意 lifecycle 不一定是管理 ViewModel 的 Lifecycle
@Deprecated('use context.withLifecycleAndViewModelEffect()')
VM useLifecycleViewModelEffect<VM extends ViewModel>({
  VM? data,
  VM Function()? factory,
  VM Function(Lifecycle lifecycle)? factory2,
  LifecycleEffectTask<VM>? launchOnFirstCreate,
  LifecycleEffectTask<VM>? launchOnFirstStart,
  LifecycleEffectTask<VM>? launchOnFirstResume,
  LifecycleEffectTask<VM>? launchOnDestroy,
  LifecycleEffectTask<VM>? repeatOnStarted,
  LifecycleEffectTask<VM>? repeatOnResumed,
  ViewModelProvider Function(Lifecycle)? viewModelProvider,
  ViewModelProvider Function(LifecycleOwner lifecycleOwner)? viewModelProvider2,
}) =>
    useLifecycleAndViewModelEffect(
      data: data,
      factory: factory,
      factory2: factory2,
      launchOnFirstCreate: launchOnFirstCreate,
      launchOnFirstStart: launchOnFirstStart,
      launchOnFirstResume: launchOnFirstResume,
      launchOnDestroy: launchOnDestroy,
      repeatOnStarted: repeatOnStarted,
      repeatOnResumed: repeatOnResumed,
      viewModelProviderProducer: viewModelProvider2 ??
          (viewModelProvider == null
              ? null
              : (owner) => viewModelProvider(owner.lifecycle)),
    );

/// 对于 ViewModel 在当前生命周期事件中执行
/// 取当前 环境中唯一的 ViewModel 对象 与 其他的 hook 中的 use 不同
/// 注意 lifecycle 不一定是管理 ViewModel 的 Lifecycle
@Deprecated('use viewModels() and withLifecycleEffect()')
VM useLifecycleAndViewModelEffect<VM extends ViewModel>({
  VM? data,
  VM Function()? factory,
  VM Function(Lifecycle lifecycle)? factory2,
  LifecycleEffectTask<VM>? launchOnFirstCreate,
  LifecycleEffectTask<VM>? launchOnFirstStart,
  LifecycleEffectTask<VM>? launchOnFirstResume,
  LifecycleEffectTask<VM>? launchOnDestroy,
  LifecycleEffectTask<VM>? repeatOnStarted,
  LifecycleEffectTask<VM>? repeatOnResumed,
  ViewModelProvider Function(LifecycleOwner lifecycleOwner)?
      viewModelProviderProducer,
}) {
  //  ignore: deprecated_member_use_from_same_package
  return useContext().withLifecycleAndViewModelEffect(
    data: data,
    factory: factory,
    factory2: factory2,
    viewModelProviderProducer: viewModelProviderProducer,
    launchOnFirstCreate: launchOnFirstCreate,
    launchOnFirstStart: launchOnFirstStart,
    launchOnFirstResume: launchOnFirstResume,
    launchOnDestroy: launchOnDestroy,
    repeatOnStarted: repeatOnStarted,
    repeatOnResumed: repeatOnResumed,
  );
}
