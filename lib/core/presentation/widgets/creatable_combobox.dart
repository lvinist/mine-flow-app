import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

/// A combobox that allows users to select from a predefined list of items or
/// type a new value to dynamically create a new option.
///
/// Uses ForUI styling tokens (`FTheme`) per the design system (Doc 07).
///
/// Type parameter `T` is the data type of each option in [items].
///
/// ## Behaviour
/// - The text field filters [items] by the typed query (case-insensitive).
/// - If the typed text does not match any existing item, an "Add `<text>`" tile
///   is shown at the top of the dropdown. Selecting it calls [onCreateNew].
/// - Selecting an existing item calls [onChanged] and clears the text field.
/// - The dropdown opens on focus and closes on selection or loss of focus.
///
/// ## Keyboard accessibility
/// - **Tab** / **Shift+Tab** moves focus in/out of the field.
/// - **ArrowUp** / **ArrowDown** navigates the option list.
/// - **Enter** selects the highlighted option.
/// - **Escape** closes the dropdown without selecting.
class CreatableCombobox<T> extends StatefulWidget {
  /// The list of selectable items.
  final List<T> items;

  /// Converts an item to its display string.
  final String Function(T item) labelBuilder;

  /// Called when an existing item is selected.
  final ValueChanged<T>? onChanged;

  /// Called when the user opts to create a new item with the typed text.
  final ValueChanged<String>? onCreateNew;

  /// Optional initial text value.
  final String initialValue;

  /// Label shown above the text field.
  final String? label;

  /// Hint text shown inside the text field when empty.
  final String? hint;

  /// Optional prefix widget shown inside the text field.
  final Widget? prefix;

  /// The currently selected item, if any.
  final T? selectedItem;

  const CreatableCombobox({
    super.key,
    required this.items,
    required this.labelBuilder,
    this.onChanged,
    this.onCreateNew,
    this.initialValue = '',
    this.label,
    this.hint,
    this.prefix,
    this.selectedItem,
  });

  @override
  State<CreatableCombobox<T>> createState() => _CreatableComboboxState<T>();
}

class _CreatableComboboxState<T> extends State<CreatableCombobox<T>> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _listScrollController = ScrollController();

  /// Index of the currently highlighted option in the filtered list.
  int _highlightedIndex = -1;

  /// Whether the dropdown list is visible.
  bool _isOpen = false;

  /// Filtered items derived from the current query.
  List<T> get _filteredItems {
    final query = _textController.text.toLowerCase().trim();
    if (query.isEmpty) return widget.items;
    return widget.items.where((item) {
      final label = widget.labelBuilder(item).toLowerCase();
      return label.contains(query);
    }).toList();
  }

  /// Whether the current query matches no existing item (shows "Add new" tile).
  bool get _queryMatchesNone {
    final query = _textController.text.trim();
    if (query.isEmpty) return false;
    return !widget.items.any(
      (item) => widget.labelBuilder(item).toLowerCase() == query.toLowerCase(),
    );
  }

  @override
  void initState() {
    super.initState();
    _textController.text = widget.initialValue;
    _focusNode.addListener(_onFocusChange);
    _textController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(CreatableCombobox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _textController.text) {
      _textController.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _textController.removeListener(_onTextChanged);
    _focusNode.dispose();
    _textController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isOpen = _focusNode.hasFocus;
      if (!_isOpen) {
        _highlightedIndex = -1;
      }
    });
  }

  void _onTextChanged() {
    setState(() {
      _highlightedIndex = -1;
    });
  }

  void _selectItem(T item) {
    _textController.clear();
    _focusNode.unfocus();
    widget.onChanged?.call(item);
  }

  void _createNew(String text) {
    _textController.clear();
    _focusNode.unfocus();
    widget.onCreateNew?.call(text);
  }

  /// Handles key events for navigating the option list with arrow keys and
  /// selecting with Enter, or dismissing with Escape.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final filtered = _filteredItems;
    final hasAddNew = _queryMatchesNone;
    final totalOptions = filtered.length + (hasAddNew ? 1 : 0);

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _highlightedIndex = (_highlightedIndex + 1).clamp(0, totalOptions - 1);
      });
      _scrollToHighlighted();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlightedIndex = (_highlightedIndex - 1).clamp(-1, totalOptions - 1);
        if (_highlightedIndex < 0) _highlightedIndex = -1;
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < filtered.length) {
        _selectItem(filtered[_highlightedIndex]);
        return KeyEventResult.handled;
      }
      if (hasAddNew && _highlightedIndex == filtered.length) {
        _createNew(_textController.text.trim());
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _focusNode.unfocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollToHighlighted() {
    if (_highlightedIndex < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listScrollController.hasClients) {
        final offset = _highlightedIndex * 44.0;
        _listScrollController.animateTo(
          offset.clamp(0.0, _listScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final filtered = _filteredItems;
    final hasAddNew = _queryMatchesNone;
    final query = _textController.text.trim();

    // Build the prefix icon if provided (via theme-aware Row wrapper,
    // since FTextField.prefix is not available in this forui version).
    final inputPrefix = widget.prefix != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [widget.prefix!, const SizedBox(width: 8)],
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Optional label
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.label!,
              style: theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colors.foreground,
              ),
            ),
          ),
        ],

        // Text field wrapped in Focus for keyboard handling
        Focus(
          focusNode: _focusNode,
          onKeyEvent: _onKeyEvent,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colors.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.colors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Row(
              children: [
                if (inputPrefix != null) inputPrefix,
                Expanded(
                  child: FTextField(
                    control: FTextFieldControl.managed(
                      controller: _textController,
                    ),
                    hint: widget.hint,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Dropdown list
        if (_isOpen && (filtered.isNotEmpty || hasAddNew))
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: theme.colors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.colors.border),
              boxShadow: [
                BoxShadow(
                  color: theme.colors.foreground.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView(
              controller: _listScrollController,
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                // "Add new" tile when query matches nothing
                if (hasAddNew)
                  _ListTile(
                    label: 'Tambah "$query"',
                    icon: Icons.add_circle_outline,
                    isHighlighted: _highlightedIndex == filtered.length,
                    theme: theme,
                    onTap: () => _createNew(query),
                  ),

                // Filtered items
                for (var i = 0; i < filtered.length; i++)
                  _ListTile(
                    label: widget.labelBuilder(filtered[i]),
                    icon: null,
                    isHighlighted: _highlightedIndex == i,
                    theme: theme,
                    onTap: () => _selectItem(filtered[i]),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Internal list tile widget used inside the [CreatableCombobox] dropdown.
///
/// Highlights when [isHighlighted] is true (keyboard navigation) and
/// calls [onTap] when pressed.
class _ListTile extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isHighlighted;
  final FThemeData theme;
  final VoidCallback onTap;

  const _ListTile({
    required this.label,
    this.icon,
    required this.isHighlighted,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isHighlighted
                ? theme.colors.muted.withValues(alpha: 0.5)
                : theme.colors.background,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: theme.colors.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
