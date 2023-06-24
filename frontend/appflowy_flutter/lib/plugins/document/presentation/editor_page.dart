import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_list.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/database/referenced_database_menu_tem.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// AppFlowy编辑器页面的状态管理类
class AppFlowyEditorPage extends StatefulWidget {
  const AppFlowyEditorPage({
    super.key,
    required this.editorState, // 编辑器的状态
    this.header, // 页面的头部
    this.shrinkWrap = false, // 是否自适应内容的长度
    this.scrollController, // 滚动控制器
    this.autoFocus, // 是否自动聚焦
    required this.styleCustomizer, // 编辑器样式定制
  });

  final Widget? header;
  final EditorState editorState;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final bool? autoFocus;
  final EditorStyleCustomizer styleCustomizer;

  @override
  State<AppFlowyEditorPage> createState() => _AppFlowyEditorPageState();
}

class _AppFlowyEditorPageState extends State<AppFlowyEditorPage> {
  late final ScrollController effectiveScrollController;

  // 编辑器命令快捷键事件
  final List<CommandShortcutEvent> commandShortcutEvents = [
    ...codeBlockCommands,
    ...standardCommandShortcutEvents,
  ];

  // 工具栏项目
  final List<ToolbarItem> toolbarItems = [
    smartEditItem,
    paragraphItem,
    ...headingItems,
    ...markdownFormatItems,
    quoteItem,
    bulletedListItem,
    numberedListItem,
    linkItem,
    textColorItem,
    highlightColorItem,
  ];

  // /菜单项
  late final slashMenuItems = [
    inlineGridMenuItem(documentBloc),
    referencedGridMenuItem,
    inlineBoardMenuItem(documentBloc),
    referencedBoardMenuItem,
    inlineCalendarMenuItem(documentBloc),
    referencedCalendarMenuItem,
    calloutItem,
    mathEquationItem,
    codeBlockItem,
    emojiMenuItem,
    autoGeneratorMenuItem,
  ];

  // 编辑器区块构建器
  late final Map<String, BlockComponentBuilder> blockComponentBuilders =
      _customAppFlowyBlockComponentBuilders();

  // 编辑器字符快捷键事件
  List<CharacterShortcutEvent> get characterShortcutEvents => [
        // 代码块字符事件
        ...codeBlockCharacterEvents,

        // toggle list
        // formatGreaterToToggleList,

        // 自定义/命令
        customSlashCommand(
          slashMenuItems,
          style: styleCustomizer.selectionMenuStyleBuilder(),
        ),

        ...standardCharacterShortcutEvents
          ..removeWhere(
            (element) => element == slashCommand,
          ), // 移除默认的/命令
      ];

  // 显示/命令菜单
  late final showSlashMenu = customSlashCommand(
    slashMenuItems,
    shouldInsertSlash: false,
    style: styleCustomizer.selectionMenuStyleBuilder(),
  ).handler;

  EditorStyleCustomizer get styleCustomizer => widget.styleCustomizer;

  DocumentBloc get documentBloc => context.read<DocumentBloc>();

  @override
  void initState() {
    super.initState();
    // 初始化滚动控制器
    effectiveScrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    // 如果没有自定义滚动控制器，则销毁它
    if (widget.scrollController == null) {
      effectiveScrollController.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bool autoFocus, Selection? selection) =
        _computeAutoFocusParameters();

    // 创建编辑器
    final editor = AppFlowyEditor.custom(
      editorState: widget.editorState,
      editable: true,
      shrinkWrap: widget.shrinkWrap,
      scrollController: effectiveScrollController,
      // 设置自动聚焦参数
      autoFocus: widget.autoFocus ?? autoFocus,
      focusedSelection: selection,
      // 设置主题
      editorStyle: styleCustomizer.style(),
      // 定制块构建器
      blockComponentBuilders: blockComponentBuilders,
      // 定制快捷键
      characterShortcutEvents: characterShortcutEvents,
      commandShortcutEvents: commandShortcutEvents,
      header: widget.header,
    );

    // 创建浮动工具栏
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
        ),
        child: FloatingToolbar(
          style: styleCustomizer.floatingToolbarStyleBuilder(),
          items: toolbarItems,
          editorState: widget.editorState,
          scrollController: effectiveScrollController,
          child: editor,
        ),
      ),
    );
  }

  // 创建AppFlowy区块构建器
  Map<String, BlockComponentBuilder> _customAppFlowyBlockComponentBuilders() {
    final standardActions = [
      OptionAction.delete,
      OptionAction.duplicate,
      // OptionAction.divider,
      // OptionAction.moveUp,
      // OptionAction.moveDown,
    ];

    final configuration = BlockComponentConfiguration(
      padding: (_) => const EdgeInsets.symmetric(vertical: 4.0),
    );
    final customBlockComponentBuilderMap = {
      PageBlockKeys.type: PageBlockComponentBuilder(),
      ParagraphBlockKeys.type: TextBlockComponentBuilder(
        configuration: configuration,
      ),
      TodoListBlockKeys.type: TodoListBlockComponentBuilder(
        configuration: configuration.copyWith(
          placeholderText: (_) => 'To-do',
        ),
      ),
      BulletedListBlockKeys.type: BulletedListBlockComponentBuilder(
        configuration: configuration.copyWith(
          placeholderText: (_) => 'List',
        ),
      ),
      NumberedListBlockKeys.type: NumberedListBlockComponentBuilder(
        configuration: configuration.copyWith(
          placeholderText: (_) => 'List',
        ),
      ),
      QuoteBlockKeys.type: QuoteBlockComponentBuilder(
        configuration: configuration.copyWith(
          placeholderText: (_) => 'Quote',
        ),
      ),
      HeadingBlockKeys.type: HeadingBlockComponentBuilder(
        configuration: configuration.copyWith(
          padding: (_) => const EdgeInsets.only(top: 12.0, bottom: 4.0),
          placeholderText: (node) =>
              'Heading ${node.attributes[HeadingBlockKeys.level]}',
        ),
        textStyleBuilder: (level) => styleCustomizer.headingStyleBuilder(level),
      ),
      ImageBlockKeys.type: ImageBlockComponentBuilder(
        configuration: configuration,
      ),
      DatabaseBlockKeys.gridType: DatabaseViewBlockComponentBuilder(
        configuration: configuration,
      ),
      DatabaseBlockKeys.boardType: DatabaseViewBlockComponentBuilder(
        configuration: configuration,
      ),
      DatabaseBlockKeys.calendarType: DatabaseViewBlockComponentBuilder(
        configuration: configuration,
      ),
      CalloutBlockKeys.type: CalloutBlockComponentBuilder(
        configuration: configuration,
      ),
      DividerBlockKeys.type: DividerBlockComponentBuilder(),
      MathEquationBlockKeys.type: MathEquationBlockComponentBuilder(
        configuration: configuration.copyWith(
          padding: (_) => const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
      CodeBlockKeys.type: CodeBlockComponentBuilder(
        configuration: configuration.copyWith(
          textStyle: (_) => styleCustomizer.codeBlockStyleBuilder(),
          placeholderTextStyle: (_) => styleCustomizer.codeBlockStyleBuilder(),
        ),
        padding: const EdgeInsets.only(
          left: 30,
          right: 30,
          bottom: 36,
        ),
      ),
      AutoCompletionBlockKeys.type: AutoCompletionBlockComponentBuilder(),
      SmartEditBlockKeys.type: SmartEditBlockComponentBuilder(),
      ToggleListBlockKeys.type: ToggleListBlockComponentBuilder(),
    };

    final builders = {
      ...standardBlockComponentBuilderMap,
      ...customBlockComponentBuilderMap,
    };

    // customize the action builder. actually, we can customize them in their own builder. Put them here just for convenience.
    for (final entry in builders.entries) {
      if (entry.key == PageBlockKeys.type) {
        continue;
      }
      final builder = entry.value;

      // customize the action builder.
      final supportColorBuilderTypes = [
        ParagraphBlockKeys.type,
        HeadingBlockKeys.type,
        BulletedListBlockKeys.type,
        NumberedListBlockKeys.type,
        QuoteBlockKeys.type,
        TodoListBlockKeys.type,
        CalloutBlockKeys.type
      ];

      final supportAlignBuilderType = [
        ImageBlockKeys.type,
      ];

      final colorAction = [
        OptionAction.divider,
        OptionAction.color,
      ];

      final alignAction = [
        OptionAction.divider,
        OptionAction.align,
      ];

      final List<OptionAction> actions = [
        ...standardActions,
        if (supportColorBuilderTypes.contains(entry.key)) ...colorAction,
        if (supportAlignBuilderType.contains(entry.key)) ...alignAction,
      ];

      builder.showActions = (_) => true;
      builder.actionBuilder = (context, state) => BlockActionList(
            blockComponentContext: context,
            blockComponentState: state,
            editorState: widget.editorState,
            actions: actions,
            showSlashMenu: () => showSlashMenu(
              widget.editorState,
            ),
          );
    }
    return builders;
  }

  // 计算自动聚焦参数
  (bool, Selection?) _computeAutoFocusParameters() {
    // 如果文档为空，则返回默认的自动聚焦参数
    if (widget.editorState.document.isEmpty) {
      return (true, Selection.collapse([0], 0));
    }
    // 如果文档的所有元素都为空，则返回对第一个元素的聚焦
    final nodes = widget.editorState.document.root.children
        .where((element) => element.delta != null);
    final isAllEmpty =
        nodes.isNotEmpty && nodes.every((element) => element.delta!.isEmpty);
    if (isAllEmpty) {
      return (true, Selection.collapse(nodes.first.path, 0));
    }
    // 否则不自动聚焦
    return const (false, null);
  }
}
