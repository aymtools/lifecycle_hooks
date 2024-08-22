import 'dart:async';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_lifecycle_viewmodel/an_lifecycle_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:weak_collections/weak_collections.dart' as weak;

/// A [Widget] that can use a [Hook].
///
/// Its usage is very similar to [StatelessWidget].
/// [HookWidget] does not have any life cycle and only implements
/// the [build] method.
///
/// The difference is that it can use a [Hook], which allows a
/// [HookWidget] to store mutable data without implementing a [State].
abstract class LHookWidget extends StatelessWidget {
  /// Initializes [key] for subclasses.
  const LHookWidget({super.key});

  @override
  StatelessElement createElement() => _StatelessHookElement(this);
}

class _StatelessHookElement extends StatelessElement
    with HookElement, LifecycleRegistryElementMixin {
  _StatelessHookElement(LHookWidget super.hooks);
}

/// A [StatefulWidget] that can use a [Hook].
///
/// Its usage is very similar to that of [StatefulWidget], but uses hooks inside [State.build].
///
/// The difference is that it can use a [Hook], which allows a
/// [HookWidget] to store mutable data without implementing a [State].
abstract class LStatefulHookWidget extends StatefulWidget {
  /// Initializes [key] for subclasses.
  const LStatefulHookWidget({super.key});

  @override
  StatefulElement createElement() => _StatefulHookElement(this);
}

class _StatefulHookElement extends StatefulElement
    with HookElement, LifecycleRegistryElementMixin {
  _StatefulHookElement(LStatefulHookWidget super.hooks);
}

final Map<BuildContext, _HookLifecycleRegistry> _hooksLifecycleRegistry =
    weak.WeakMap();

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
}

///  将hook的内容转换为lifecycle
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
    }

    hookLifecycle._hooks.add(this);

    if (hookLifecycle.firstOrNullHook == this) {
      //ignore
      hookLifecycle.lifecycleDelegate.initState();
    }
  }

  @override
  void build(BuildContext context) {
    var hookLifecycle = _hooksLifecycleRegistry[context];
    _ctx = context;

    if (hookLifecycle?.firstOrNullHook == this &&
        hookLifecycle!.currentLifecycleState < LifecycleState.started) {
      hookLifecycle.lifecycleDelegate.didChangeDependencies();
    }
  }

  @override
  void dispose() {
    if (_ctx == null) return;

    ///等待最后一个hook销毁时 销毁lifecycle
    var hookLifecycle = _hooksLifecycleRegistry[_ctx];
    hookLifecycle?._hooks.remove(this);
    if (hookLifecycle?.lastOrNullHook == this) {
      hookLifecycle!.lifecycleDelegate.dispose();
      _hooksLifecycleRegistry.remove(_ctx);
    }
    _ctx = null;
  }
}

///使用lifecycleRegistry相关
ILifecycleRegistry useLifecycleRegistry() {
  final context = useContext();
  if (context is ILifecycleRegistry) {
    return context as ILifecycleRegistry;
  } else if (context is StatefulElement &&
      context.state is ILifecycleRegistry) {
    return (context.state as ILifecycleRegistry);
  }
  use(const LifecycleHook());
  return _hooksLifecycleRegistry[context]!;
}

///使用lifecycle相关
Lifecycle useLifecycle() {
  final context = useContext();
  return Lifecycle.of(context);
}

typedef LifecycleEffectTask<T> = FutureOr Function(Lifecycle lifecycle, T data);

class _LifecycleEffectKey {
  final Object? key;

  _LifecycleEffectKey(this.key);

  @override
  int get hashCode => Object.hash(_LifecycleEffectKey, key.hashCode);

  @override
  bool operator ==(Object other) =>
      other is _LifecycleEffectKey && other.key == key;
}

/// 对于某个对象及其类型 在生命周期事件中执行
/// 取当前lifecycle环境中类型唯一的对象 与 其他的hook中的use不同
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
  final life = useLifecycle();

  return life.withLifecycleEffect(
    factory: () => life.lifecycleExtData.putIfAbsent(
        TypedKey<T>(_LifecycleEffectKey(key)),
        () => data ?? factory?.call() ?? factory2!.call(life)),
    launchOnFirstCreate: _convertLifecycleEffectTask(life, launchOnFirstCreate),
    launchOnFirstStart: _convertLifecycleEffectTask(life, launchOnFirstStart),
    launchOnFirstResume: _convertLifecycleEffectTask(life, launchOnFirstResume),
    launchOnDestroy: _convertLifecycleEffectTask(life, launchOnDestroy),
    repeatOnStarted: _convertLifecycleEffectTask(life, repeatOnStarted),
    repeatOnResumed: _convertLifecycleEffectTask(life, repeatOnResumed),
  );
}

/// 对于ViewModel 在生命周期事件中执行
/// 取当前lifecycle环境中类型唯一的ViewModel对象 与 其他的hook中的use不同
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
}) {
  final life = useLifecycle();
  return life.withLifecycleEffect(
    factory: () => life.lifecycleExtData
        .putIfAbsent(TypedKey<VM>(useLifecycleViewModelEffect), () {
      VM Function(Lifecycle)? vmFactory;
      if (data != null) {
        vmFactory = (_) => data;
      }
      if (vmFactory == null && factory != null) {
        vmFactory = (_) => factory();
      }
      if (vmFactory == null && factory2 != null) {
        vmFactory = factory2;
      }
      if (viewModelProvider != null) {
        final provider = viewModelProvider(life);
        if (vmFactory != null) {
          provider.addFactory2<VM>(vmFactory);
        }
        return provider.get<VM>();
      }
      return life.owner.viewModels<VM>(factory2: vmFactory);
    }),
    launchOnFirstCreate: _convertLifecycleEffectTask(life, launchOnFirstCreate),
    launchOnFirstStart: _convertLifecycleEffectTask(life, launchOnFirstStart),
    launchOnFirstResume: _convertLifecycleEffectTask(life, launchOnFirstResume),
    launchOnDestroy: _convertLifecycleEffectTask(life, launchOnDestroy),
    repeatOnStarted: _convertLifecycleEffectTask(life, repeatOnStarted),
    repeatOnResumed: _convertLifecycleEffectTask(life, repeatOnResumed),
  );
}

FutureOr Function(T data)? _convertLifecycleEffectTask<T>(
        Lifecycle lifecycle, FutureOr Function(Lifecycle, T)? callback) =>
    callback == null ? null : (data) => callback(lifecycle, data);
