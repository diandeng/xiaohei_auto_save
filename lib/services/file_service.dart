import 'dart:io';

class FileService {
  final String? backupPath;
  final String? originPath;

  FileService({this.backupPath, this.originPath});
  void backupFiles({required bool isAutoSave}) {
    if (originPath != null && backupPath != null) {
      final originDir = Directory(originPath!);
      final backupDir = Directory(backupPath!);

      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }

      if (originDir.existsSync()) {
        final backupDirName = DateTime.now().toString().split('.').first.replaceAll(':', '-')+ (isAutoSave ? ' (自动保存)' : '');
        final newBackupDir = Directory('${backupDir.path}\\$backupDirName');
        newBackupDir.createSync();

        originDir.listSync().forEach((entity) {
          if (entity is Directory) {
            final newDir = Directory('${newBackupDir.path}\\${entity.path.split('\\').last}');
            newDir.createSync(recursive: true);
            entity.listSync().forEach((child) {
              File(child.path).copySync('${newDir.path}\\${child.path.split('\\').last}');
            });
          } else if (entity is File) {
            File(entity.path).copySync('${newBackupDir.path}\\${entity.path.split('\\').last}');
          }
        });
      }
    }
  }

  void restoreFiles(String backupName, Function(String) showError) {
    if (originPath != null && backupPath != null) {
      final backupDir = Directory('$backupPath\\$backupName');
      final originDir = Directory(originPath!);

      if (originDir.existsSync()) {
        try {
          originDir.deleteSync(recursive: true);
          originDir.createSync(recursive: true);
        } catch (e) {
          showError('无法删除原始文件夹。请确保文件未被其他应用程序使用。\n错误信息: $e');
          return;
        }
      }

      backupDir.listSync().forEach((entity) {
        if (entity is Directory) {
          final newDir = Directory('${originDir.path}\\${entity.path.split('\\').last}');
          newDir.createSync(recursive: true);
          entity.listSync().forEach((child) {
            try {
              File(child.path).copySync('${newDir.path}\\${child.path.split('\\').last}');
            } catch (e) {
              showError('无法还原文件: ${child.path}\n错误信息: $e');
            }
          });
        } else if (entity is File) {
          try {
            File(entity.path).copySync('${originDir.path}\\${entity.path.split('\\').last}');
          } catch (e) {
            showError('无法还原文件: ${entity.path}\n错误信息: $e');
          }
        }
      });
    }
  }

  void deleteBackupFiles(String backupName, Function(String) showError) {
    if (backupPath != null) {
      final backupDir = Directory('$backupPath\\$backupName');
      if (backupDir.existsSync()) {
        try {
          backupDir.deleteSync(recursive: true);
        } catch (e) {
          showError('删除备份时发生错误: $e');
        }
      }
    }
  }

  void clearBackupFiles(Function(String) showError) {
    if (backupPath != null) {
      final backupDir = Directory(backupPath!);
      if (backupDir.existsSync()) {
        try {
          backupDir.listSync().forEach((entity) {
            if (entity is Directory) {
              entity.deleteSync(recursive: true);
            } else if (entity is File) {
              entity.deleteSync();
            }
          });
        } catch (e) {
          showError('清除备份时发生错误: $e');
        }
      }
    }
  }
}