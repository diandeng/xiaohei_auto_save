import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xiaohei_auto_save/data/app_config.dart';
import 'package:xiaohei_auto_save/data/theme_color.dart';
import 'package:xiaohei_auto_save/services/auto_save_timer.dart';
import 'package:xiaohei_auto_save/services/file_service.dart';
import 'package:xiaohei_auto_save/services/preferences_manager.dart';
import 'package:xiaohei_auto_save/utils/dialog_utils.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  String? _backupPath;
  String? _originPath;
  List<String> _backupList = [];
  late AutoSaveTimer _autoSaveTimer;
  bool _isAutoSaveEnabled = false;
  int _autoSaveInterval = 5; // 默认每5分钟保存一次
  Duration _remainingTime = Duration.zero;

  late FileService _fileService;
  int _selectedIndex = 0;
  bool isMaximized = false;

  bool isMiniMode = false; // 记录是否处于Mini模式
  final GlobalKey _miniModeKey = GlobalKey(); // 用于计算Mini模式内容的大小
  late Offset _position;
  late Size _size;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initAutoSaveTimer();
    _initPaths();
    windowManager.addListener(this);
    _checkWindowState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this as WindowListener);
    _autoSaveTimer.dispose();
    super.dispose();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAutoSaveEnabled = prefs.getBool('isAutoSaveEnabled') ?? false;
      _autoSaveInterval = prefs.getInt('autoSaveInterval') ?? 5;
    });
    _initAutoSaveTimer();
  }

  void _initAutoSaveTimer() {
    if (_isAutoSaveEnabled) {
      _autoSaveTimer = AutoSaveTimer(
        intervalMinutes: _autoSaveInterval,
        onSave: () {
          _backupFiles(isAutoSave: true);
        },
        onTick: (remainingTime) {
          setState(() {
            _remainingTime = remainingTime;
          });
        },
      );
    }
  }

  void _toggleAutoSave(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAutoSaveEnabled = value;
      prefs.setBool('isAutoSaveEnabled', value);
      _initAutoSaveTimer();
    });
  }

  void _setAutoSaveInterval(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSaveInterval = minutes;
      prefs.setInt('autoSaveInterval', minutes);
      _autoSaveTimer.setIntervalMinutes(minutes);
    });
  }

  void _initPaths() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _backupPath = prefs.getString('backupPath') ??
          '${Platform.environment['USERPROFILE']!}\\Desktop\\小黑课堂考生文件夹备份';
      _originPath =
          prefs.getString('originPath') ?? 'D:\\xhktSoft\\office2\\xhkt\\考生文件夹';
    });

    _fileService =
        FileService(backupPath: _backupPath, originPath: _originPath);

    _loadBackupList();
  }

  Future<void> _pickDirectoryPath(String key) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        if (key == 'backupPath') {
          _backupPath = result;
          PreferencesManager.setBackupPath(result);
        } else {
          _originPath = result;
          PreferencesManager.setOriginPath(result);
        }
        _fileService =
            FileService(backupPath: _backupPath, originPath: _originPath);
      });
    }
  }

  void _pickBackupPath() => _pickDirectoryPath('backupPath');

  void _pickOriginPath() => _pickDirectoryPath('originPath');

  void _loadBackupList() {
    if (_backupPath != null) {
      final backupDir = Directory(_backupPath!);
      setState(() {
        _backupList = backupDir
            .listSync()
            .whereType<Directory>()
            .map((item) => item.path.split('\\').last)
            .toList();
      });
    }
  }

  void _backupFiles({required bool isAutoSave}) {
    _fileService.backupFiles(isAutoSave: isAutoSave);
    _loadBackupList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAutoSave ? '自动保存成功！' : '备份成功！'),
        duration: const Duration(seconds: 2),
      ),
    );
    if (_isAutoSaveEnabled) {
      _autoSaveTimer.reset();
    }
  }

  void _restoreFiles(String backupName) {
    bool restoreSuccess = true;
    _fileService.restoreFiles(backupName, (error) {
      restoreSuccess = false;
      DialogUtils.showSimpleDialog(
        context: context,
        title: '错误',
        content: error,
      );
    });
    if (restoreSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('还原成功！'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteBackup(String backupName) {
    bool deleteSuccess = true;
    _fileService.deleteBackupFiles(backupName, (error) {
      deleteSuccess = false;
      DialogUtils.showSimpleDialog(
        context: context,
        title: '错误',
        content: error,
      );
    });
    if (deleteSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('删除成功！'),
          duration: Duration(seconds: 2),
        ),
      );
      _loadBackupList();
    }
  }

  void _clearBackupFiles() {
    _fileService.clearBackupFiles((error) {
      DialogUtils.showSimpleDialog(
        context: context,
        title: '错误',
        content: error,
      );
    });
    _loadBackupList();
  }

  void _updateThemeColor(Color color, bool isDark) async {
    PreferencesManager.setThemeColor(color);
    AdaptiveTheme.of(context).setTheme(
      light: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: color,
      ),
      dark: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: color,
      ),
    );
    if (isDark) {
      AdaptiveTheme.of(context).setDark();
    } else {
      AdaptiveTheme.of(context).setLight();
    }
  }

  Widget _getSelectedContent() {
    if (isMiniMode) {
      return _buildMiniMode(); // 返回Mini模式的布局
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              _selectedIndex == 0
                  ? '备份列表'
                  : _selectedIndex == 1
                      ? '设置'
                      : '关于',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(16.0),
              ),
              padding: const EdgeInsets.all(16.0),
              child: _buildContent(),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildMiniMode() {
    return Center(
      child: Container(
        key: _miniModeKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _backupFiles(isAutoSave: false);
                  },
                  icon: const Icon(Icons.backup),
                  label: const Text('备份'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_backupList.isNotEmpty) {
                      _restoreFiles(_backupList.last); // 还原最近的一次备份
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('没有可还原的备份'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('还原'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _toggleMiniMode,
              icon: const Icon(Icons.dashboard_customize),
              label: const Text('退出Mini模式'),
            ),
            Text(
              '工具将在 ${_remainingTime.inMinutes} 分 ${_remainingTime.inSeconds % 60} 秒后自动备份',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildBackupList();
      case 1:
        return _buildSettings();
      case 2:
        return _buildAbout();
      default:
        return _buildBackupList();
    }
  }

  Widget _buildBackupList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            itemCount: _backupList.length,
            itemBuilder: (context, index) {
              final backupName = _backupList[index];
              return ListTile(
                title: Text(backupName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                        message: '还原',
                        child: IconButton(
                          icon: const Icon(Icons.restore),
                          onPressed: () {
                            _restoreFiles(backupName);
                          },
                        )),
                    Tooltip(
                        message: '删除',
                        child: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            DialogUtils.showAlertDialog(
                                context: context,
                                title: '警告',
                                content: '确定要删除备份“$backupName”吗？',
                                onConfirm: () {
                                  _deleteBackup(backupName);
                                });
                          },
                        )),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                if (_backupPath != null) {
                  Process.run('explorer.exe', [_backupPath!]);
                }
              },
              icon: const Icon(Icons.folder_open),
              label: const Text('打开备份文件夹'),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onLongPress: () {
                DialogUtils.showAlertDialog(
                    context: context,
                    title: '警告',
                    content: '此操作将清除所有备份文件，是否继续？',
                    onConfirm: _clearBackupFiles);
              },
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('长按按钮以清除备份'),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                label: const Text('清除备份'),
                icon: const Icon(Icons.clear_all),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ElevatedButton(
          onPressed: _pickBackupPath,
          child: const Text('选择备份文件夹'),
        ),
        Text(
          _backupPath != null ? '备份文件夹: $_backupPath' : '未选择备份文件夹',
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _pickOriginPath,
          child: const Text('选择考生文件夹'),
        ),
        Text(
          _originPath != null ? '考生文件夹: $_originPath' : '未选择考生文件夹',
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          title: const Text('自动保存'),
          value: _isAutoSaveEnabled,
          onChanged: _toggleAutoSave,
        ),
        if (_isAutoSaveEnabled)
          Row(
            children: [
              const Text('保存间隔（分钟）: '),
              DropdownButton<int>(
                value: _autoSaveInterval,
                items: List.generate(15, (index) => index + 1)
                    .map((minute) =>
                        DropdownMenuItem(value: minute, child: Text('$minute')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _setAutoSaveInterval(value);
                  }
                },
              ),
            ],
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            ElevatedButton(
                onPressed: () {
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.remove('backupPath');
                    prefs.remove('originPath');
                    _initPaths();
                  });
                },
                child: const Text('恢复默认设置')),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      ThemeColor themeColor = ThemeColor();
                      return SimpleDialog(
                        title: const Text('选择颜色'),
                        children: themeColor.colors.map((colorOption) {
                          return ListTile(
                            title: Text(colorOption['name']),
                            onTap: () {
                              Navigator.pop(context);
                              _updateThemeColor(
                                  colorOption['color'], colorOption['isDark']);
                            },
                          );
                        }).toList(),
                      );
                    });
              },
              child: const Text('主题设置'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildAbout() {
    return const Align(
      alignment: Alignment.topLeft, // 确保内容靠左上角对齐
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.info, size: 24.0), // 信息图标
              SizedBox(width: 8.0), // 图标与文字间距
              Text(
                AppConfig.appName,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.0),
          Text(
            '版本：${AppConfig.version} (${AppConfig.versionCode})',
            style: TextStyle(fontSize: 16.0),
          ),
          SizedBox(height: 8.0),
          Text(
            '作者：${AppConfig.author}',
            style: TextStyle(fontSize: 16.0),
          ),
        ],
      ),
    );
  }

  Future<void> _checkWindowState() async {
    bool maximized = await windowManager.isMaximized();
    setState(() {
      isMaximized = maximized;
    });
  }

  @override
  void onWindowMaximize() {
    setState(() {
      isMaximized = true;
      if (kDebugMode) {
        print('Window Maximized');
      }
    });
  }

  @override
  void onWindowRestore() {
    setState(() {
      isMaximized = false;
      if (kDebugMode) {
        print('Window Restored');
      }
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      isMaximized = false;
      if (kDebugMode) {
        print('Window Unmaximized');
      }
    });
  }

  void _toggleMiniMode() async {
    setState(() {
      isMiniMode = !isMiniMode; // 切换模式状态
    });
    if (!isMiniMode) {
      await windowManager.setPosition(_position); //恢复原来的窗口位置
      await windowManager.setSize(_size); //恢复原来的窗口大小
      await windowManager.setResizable(true); //可调整大小
      await windowManager.setAlwaysOnTop(false); //取消置顶
    } else {
      //保存原来的窗口位置
      _position = await windowManager.getPosition();
      //保存原来的窗口大小
      _size = await windowManager.getSize();
      //获取Mini模式下的窗口大小
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final RenderBox renderBox =
            _miniModeKey.currentContext!.findRenderObject() as RenderBox;
        var size = renderBox.size;
        //16边距
        size = Size(size.width + 32, size.height + 32);
        await windowManager.setSize(size);
        await windowManager.setResizable(false);
        await windowManager.setAlwaysOnTop(true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onPanStart: (details) {
          windowManager.startDragging();
        },
        child: Scaffold(
            appBar: isMiniMode
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(kToolbarHeight),
                    child: AppBar(
                      backgroundColor:
                          Theme.of(context).colorScheme.inversePrimary,
                      title: const Text(AppConfig.appName),
                      actions: [
                        Text(
                          '工具将在 ${_remainingTime.inMinutes} 分 ${_remainingTime.inSeconds % 60} 秒后自动备份',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Tooltip(
                            message: 'Mini模式',
                            child: IconButton(
                              icon: const Icon(Icons.dashboard_customize),
                              onPressed: () async {
                                _toggleMiniMode();
                              },
                            )),
                        Tooltip(
                            message: '最小化',
                            child: IconButton(
                              icon: const Icon(Icons.minimize),
                              onPressed: () async {
                                await windowManager.minimize();
                              },
                            )),
                        Tooltip(
                            message: isMaximized ? '还原' : '最大化',
                            child: IconButton(
                              // 判断窗口是否最大化，显示不同的图标
                              icon: Icon(isMaximized
                                  ? Icons.fullscreen_exit
                                  : Icons.crop_square),
                              onPressed: () async {
                                if (isMaximized) {
                                  await windowManager.restore();
                                } else {
                                  await windowManager.maximize();
                                }
                              },
                            )),
                        Tooltip(
                            message: '关闭',
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () async {
                                await windowManager.close();
                              },
                            )),
                      ],
                    ),
                  ),
            body: Row(
              children: [
                isMiniMode
                    ? const SizedBox()
                    : NavigationRail(
                        selectedIndex: _selectedIndex,
                        groupAlignment: -1,
                        onDestinationSelected: (int index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        labelType: NavigationRailLabelType.all,
                        leading: Tooltip(
                            message: '备份',
                            child: FloatingActionButton(
                              elevation: 0,
                              onPressed: () {
                                _backupFiles(isAutoSave: false);
                              },
                              child: const Icon(Icons.backup),
                            )),
                        destinations: const <NavigationRailDestination>[
                          NavigationRailDestination(
                            icon: Icon(Icons.list),
                            label: Text('备份列表'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.tune),
                            label: Text('设置'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.info),
                            label: Text('关于'),
                          ),
                        ],
                      ),
                Expanded(
                    child: Padding(
                  padding: EdgeInsets.all(isMiniMode ? 0 : 16.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_selectedIndex),
                      child: _getSelectedContent(),
                    ),
                  ),
                ))
              ],
            )));
  }
}
