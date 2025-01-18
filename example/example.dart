import 'dart:async';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_lifecycle_hooks/an_lifecycle_hooks.dart';
import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AppViewModel with ViewModel {
  int incrementStep = 1;
}

void main() {
  //可提前注册ViewModel的factory
  ViewModelProvider.addDefFactory(AppViewModel.new);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LifecycleApp(
      child: MaterialApp(
        title: 'Lifecycle Hook Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        navigatorObservers: [
          LifecycleNavigatorObserver.hookMode(),
        ],
        home: const HomeViewModelDemo(),
      ),
    );
  }
}

class HomeService {
  final Lifecycle lifecycle;
  final ValueNotifier<int> stayed = ValueNotifier<int>(0);

  HomeService(this.lifecycle) {
    // stayed ValueNotifier 绑定到生命周期 当生命周期销毁时 自动调用 [ValueNotifier.dispose]
    stayed.bindLifecycle(lifecycle);
  }

  void startTicker() {
    // 在可见的时间 每秒增加1  不可见时不增加
    Stream.periodic(const Duration(seconds: 1))
        .bindLifecycle(lifecycle, repeatLastOnRestart: true)
        .listen((_) => stayed.value += 1);
  }
}

class HomeServiceDemo extends HookWidget {
  const HomeServiceDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // 单独使用lifecycle
    final homeService = useLifecycleEffect<HomeService>(
      factory2: HomeService.new,
      // 在首次可见时启动
      launchOnFirstResume: (_, s) => s.startTicker(),
    );
    // hooks 处理变化
    final stayed = useListenable(
      homeService.stayed,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Lifecycle Hook Demo Home Page'),
      ),
      body: Center(
        child: Text(
          'Stayed on this page for:${stayed.value} s',
        ),
      ),
    );
  }
}

class HomeViewModel with ViewModel {
  // 存放全局配置
  final AppViewModel appModel;

  // 创建一个自动管理的 ValueNotifier<int>
  late final counter = valueNotifier(0);

  //  可以从lifecycle中之前获取已存在的ViewModel
  HomeViewModel(Lifecycle lifecycle) : appModel = lifecycle.viewModelsByApp();

  void incrementCounter() {
    counter.value += appModel.incrementStep;
  }
}

class HomeViewModelDemo extends HookWidget {
  const HomeViewModelDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用viewmodel
    final viewModel = useLifecycleViewModelEffect(factory2: HomeViewModel.new);

    // hooks 处理变化
    final counter = useListenable(viewModel.counter);

    return Scaffold(
      appBar: AppBar(
        title: Text('ViewModel Hook Demo Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '${counter.value}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: const HomeFloatingButton(),
    );
  }
}

/// 模拟这是另一个widget 需要使用MyHomePage中的同一个ViewModel
class HomeFloatingButton extends HookWidget {
  const HomeFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    // 如果提前已经注册过或者确定已经存在对象则可以直接使用
    final vm = useLifecycleViewModelEffect<HomeViewModel>();
    return FloatingActionButton(
      onPressed: vm.incrementCounter,
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    );
  }
}
