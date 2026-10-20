import 'package:flutter/material.dart';
import 'package:zeno/theme/app_theme.dart';

/// Asks for a new display name. Returns the trimmed name, or null when the
/// user cancels. A blank name cannot be saved.
Future<String?> showEditNameDialog(
  BuildContext context, {
  required String current,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _EditNameDialog(current: current),
  );
}

class _EditNameDialog extends StatefulWidget {
  final String current;

  const _EditNameDialog({required this.current});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.current);

  String get _trimmed => _controller.text.trim();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_trimmed);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      title: Text('What should Mochi call you?', style: AppTheme.headlineMed),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 24,
        textCapitalization: TextCapitalization.words,
        style: AppTheme.bodyLarge,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (_trimmed.isNotEmpty) _save();
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _trimmed.isEmpty ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
