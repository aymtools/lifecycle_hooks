import 'dart:async';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_lifecycle_hooks/an_lifecycle_hooks.dart';
import 'package:an_lifecycle_viewmodel/an_lifecycle_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void main() {
  ViewModelProvider.addDefFactory2(ViewModelHome.new);
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
        home: const MyHomePage(title: 'Lifecycle Hook Demo Home Page'),
      ),
    );
  }
}

class ViewModelHome with ViewModel {
  final ValueNotifier<int> counter = ValueNotifier<int>(0);

  ViewModelHome(Lifecycle lifecycle) {
    counter.bindLifecycle(lifecycle);
  }

  void incrementCounter() {
    counter.value++;
  }
}

class MyHomePage extends HookWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final stayed = useLifecycleEffect<ValueNotifier<int>>(
      factory2: (l) => ValueNotifier(0)..bindLifecycle(l),
      launchOnFirstStart: (l, d) {
        Stream.periodic(const Duration(seconds: 1))
            .bindLifecycle(l, repeatLastOnRestart: true)
            .listen((event) => d.value++);
      },
    );
    useListenable(stayed);

    final viewModel = useLifecycleViewModelEffect<ViewModelHome>();
    // 也可使用 当前注册的构建工厂
    // final viewModel =
    //     useLifecycleViewModelEffect<ViewModelHome>(factory2: ViewModelHome.new);
    final counter = useListenable(viewModel.counter);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Stayed on this page for:${stayed.value} s',
            ),
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

class HomeFloatingButton extends HookWidget {
  const HomeFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = useLifecycleViewModelEffect<ViewModelHome>();
    return FloatingActionButton(
      onPressed: vm.incrementCounter,
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    );
  }
}
