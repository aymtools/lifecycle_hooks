A toolkit that introduces lifecycle events from the AnLifecycle library into the hooks library

## Usage

#### 1.1 Prepare the lifecycle environment.

```dart

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use LifecycleApp to wrap the default App
    return LifecycleApp(
      child: MaterialApp(
        title: 'Lifecycle Hook Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        navigatorObservers: [
          //Use LifecycleNavigatorObserver.hookMode() to register routing event changes
          LifecycleNavigatorObserver.hookMode(),
        ],
        home: const MyHomePage(title: 'Lifecycle Hook Home Page'),
      ),
    );
  }
}
```

#### 1.2 Use useLifecycle useLifecycleEffect

You can also use viewmodel related content with useLifecycleViewModelEffect

```dart 

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
      factory2: (l) =>
      ValueNotifier(0)
        ..bindLifecycle(l),
      launchOnFirstStart: (l, d) {
        Stream.periodic(const Duration(seconds: 1))
            .bindLifecycle(l, repeatLastOnRestart: true)
            .listen((event) => d.value++);
      },
    );
    useListenable(stayed);
    //需要之前存在VM的factory
    //例如  ViewModelProvider.addDefFactory2(ViewModelHome.new);
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
              style: Theme
                  .of(context)
                  .textTheme
                  .headlineMedium,
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
```

## Additional information

See [cancelable](https://github.com/aymtools/cancelable/)

See [anlifecycle](https://github.com/aymtools/lifecycle/)

See [an_lifecycle_cancellable](https://github.com/aymtools/lifecycle_cancellable/)

See [an_lifecycle_viewmodel](https://github.com/aymtools/lifecycle_viewmodel/)

See [flutter_hooks](https://pub.dev/packages/flutter_hooks)