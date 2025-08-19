A toolkit that introduces lifecycle events from the AnLifecycle library into the hooks library

# Maintenance

Maintenance will no longer be provided, please use the useContext.withXXX related extension
functions instead.

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

The current usage of PageView and TabBarViewPageView should be replaced with LifecyclePageView and
LifecycleTabBarView. Alternatively, you can wrap the items with LifecyclePageViewItem. You can refer
to [anlifecycle](https://pub.dev/packages/anlifecycle) for guidance.

#### 1.2 Use useLifecycle useLifecycleEffect

```dart

class HomeService {
  final ValueNotifier<int> stayed = ValueNotifier<int>(0);

  void startTicker(Lifecycle lifecycle) {
    // 在可见的时间 每秒增加1  不可见时不增加
    Stream.periodic(const Duration(seconds: 1))
        .bindLifecycle(lifecycle, repeatLastOnStateAtLeast: true)
        .listen((event) => stayed.value += 1);
  }
}

class HomeServiceDemo extends HookWidget {
  const HomeServiceDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // 单独使用lifecycle
    final homeService = useLifecycleEffect<HomeService>(
      factory: HomeService.new,
      // 在首次可见时启动
      launchOnFirstResume: (l, service) => service.startTicker(l),
    );
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
```

#### 1.3 You can use useLifecycleViewModelEffect to directly work with ViewModel-related functionality.

```dart 

class HomeViewModel with ViewModel {
  // 获取存放全局配置 需要已经存在或者提前已经注册过创建方式 ViewModel.factories
  //    .addFactory(AppViewModel.new, producer: ViewModel.producer.byApp);
  late final AppViewModel appModel = viewModels();

  // 创建一个自动管理的 ValueNotifier<int>
  late final counter = valueNotifier(0);

  void incrementCounter() {
    counter.value += appModel.incrementStep;
  }
}

class HomeViewModelDemo extends HookWidget {
  const HomeViewModelDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用viewmodel
    final viewModel = useLifecycleViewModelEffect(factory: HomeViewModel.new);

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
```

## Additional information

See [cancelable](https://pub.dev/packages/cancellable)

See [anlifecycle](https://pub.dev/packages/anlifecycle)

See [an_lifecycle_cancellable](https://pub.dev/packages/an_lifecycle_cancellable)

See [an_viewmodel](https://pub.dev/packages/an_viewmodel)

See [flutter_hooks](https://pub.dev/packages/flutter_hooks)