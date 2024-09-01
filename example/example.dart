import 'dart:async';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_lifecycle_hooks/an_lifecycle_hooks.dart';
import 'package:an_lifecycle_viewmodel/an_lifecycle_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void main() {
  //可提前注册ViewModel的factory
  ViewModelProvider.addDefFactory(ViewModelApp.new);
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
        home: const ViewModelHomePage(),
      ),
    );
  }
}

class HomeService {
  final ValueNotifier<int> stayed = ValueNotifier<int>(0);

  HomeService(Lifecycle lifecycle) {
    // 在可见的时间 每秒增加1  不可见时不增加
    Stream.periodic(const Duration(seconds: 1))
        .bindLifecycle(lifecycle, repeatLastOnRestart: true)
        .listen((event) => stayed.value++);
  }
}

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 单独使用lifecycle
    final homeService =
        useLifecycleEffect<HomeService>(factory2: HomeService.new);
    // hooks 处理变化
    final stayed = useListenable(homeService.stayed);
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

class ViewModelApp with ViewModel {
  int incrementStep = 1;
}

class ViewModelHome with ViewModel {
  final ValueNotifier<int> counter = ValueNotifier<int>(0);
  final ViewModelApp appModel;

  //  可以从lifecycle中之前获取已存在的ViewModel
  ViewModelHome(Lifecycle lifecycle) : appModel = lifecycle.viewModelsByApp() {
    //将ValueNotifier与VM管理 自动销毁
    counter.bindLifecycle(lifecycle);
  }

  void incrementCounter() {
    counter.value += appModel.incrementStep;
  }
}

class ViewModelHomePage extends HookWidget {
  const ViewModelHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用viewmodel
    final viewModel =
        useLifecycleViewModelEffect<ViewModelHome>(factory2: ViewModelHome.new);

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
    final vm = useLifecycleViewModelEffect<ViewModelHome>();
    return FloatingActionButton(
      onPressed: vm.incrementCounter,
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    );
  }
}
