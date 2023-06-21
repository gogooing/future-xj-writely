import 'dart:io';

import 'package:appflowy/plugins/document/presentation/share/share_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/mock/mock_file_picker.dart';
import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('share markdown in document page', () {
    const location = 'markdown';

    setUp(() async {
      await TestFolder.cleanTestLocation(location);
      await TestFolder.setTestLocation(location);
    });

    tearDown(() async {
      await TestFolder.cleanTestLocation(location);
    });

    tearDownAll(() async {
      await TestFolder.cleanTestLocation(null);
    });

    testWidgets('click the share button in document page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // expect to see a readme page
      tester.expectToSeePageName(readme);

      // mock the file picker
      final path = await mockSaveFilePath(location, 'test.md');
      // click the share button and select markdown
      await tester.tapShareButton();
      await tester.tapMarkdownButton();

      // expect to see the success dialog
      tester.expectToExportSuccess();

      final file = File(path);
      final isExist = file.existsSync();
      expect(isExist, true);
      final markdown = file.readAsStringSync();
      expect(markdown, expectedMarkdown);
    });

    testWidgets(
      'share the markdown after renaming the document name',
      (tester) async {
        await tester.initializeAppFlowy();
        await tester.tapGoButton();

        // expect to see a readme page
        tester.expectToSeePageName(readme);

        // rename the document
        await tester.hoverOnPageName(readme);
        await tester.renamePage('example');

        final shareButton = find.byType(ShareActionList);
        final shareButtonState =
            tester.state(shareButton) as ShareActionListState;
        final path =
            await mockSaveFilePath(location, '${shareButtonState.name}.md');

        // click the share button and select markdown
        await tester.tapShareButton();
        await tester.tapMarkdownButton();

        // expect to see the success dialog
        tester.expectToExportSuccess();

        final file = File(path);
        final isExist = file.existsSync();
        expect(isExist, true);
      },
    );
  });
}

const expectedMarkdown = r'''
# 欢迎使用晓君-Writely!
## 基本操作基本操作
- [ ] 单击任意位置即可开始输入。
- [ ] 高亮任何文本，使用编辑菜单来_样式化_ 你的 <u>写作</u> 任何 你想要的方式。高亮任何文本，使用编辑菜单来_样式化_ 你的 <u>写作</u> 任何 你想要的方式。
- [ ] 一旦你输入 "/" ，一个菜单会弹出。选择不同类型的内容块进行添加。
- [ ] 输入/后跟 "/bullet" 或 "/num" 创建列表。输入 "/" 后跟 "/bullet" 或 "/num" 创建列表。
- [x] 单击侧边栏底部的+ 新建页面按钮以添加新页面。
- [ ] 单击侧边栏中任何页面标题旁边的+，快速添加新子页面，文档，网格或看板板。单击侧边栏中任何页面标题旁边的+，快速添加新子页面，文档，网格或看板板。

---

## 代码块快捷键
1. 输入 "/code" 来插入代码块



''';
