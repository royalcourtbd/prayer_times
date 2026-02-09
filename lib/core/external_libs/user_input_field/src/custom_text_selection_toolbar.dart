import 'package:flutter/material.dart';

class CustomTextSelectionToolbar extends StatelessWidget {
  const CustomTextSelectionToolbar({
    super.key,
    required this.anchors,
    required this.editableTextState,
  });

  final TextSelectionToolbarAnchors anchors;

  final EditableTextState editableTextState;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: anchors.primaryAnchor.dy - 60,
          child: Card(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolBarButton(
                  context: context,
                  label: 'Cut',
                  onPressed: () {
                    editableTextState.cutSelection(
                      SelectionChangedCause.toolbar,
                    );
                    _hideToolbar();
                  },
                ),
                _buildToolBarButton(
                  context: context,
                  label: 'Copy',
                  onPressed: () {
                    editableTextState.copySelection(
                      SelectionChangedCause.toolbar,
                    );
                    _hideToolbar();
                  },
                ),
                _buildToolBarButton(
                  context: context,
                  label: 'Paste',
                  onPressed: () {
                    editableTextState.pasteText(SelectionChangedCause.toolbar);
                    _hideToolbar();
                  },
                ),
                _buildToolBarButton(
                  context: context,
                  label: 'Select All',
                  onPressed: () {
                    editableTextState.selectAll(SelectionChangedCause.toolbar);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolBarButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextSelectionToolbarTextButton(
      padding: const EdgeInsets.all(12),
      onPressed: onPressed,
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }

  void _hideToolbar() {
    ContextMenuController.removeAny();
  }
}
