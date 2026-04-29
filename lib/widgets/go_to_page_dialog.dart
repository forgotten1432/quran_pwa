import 'package:flutter/material.dart';

class GoToPageDialog extends StatefulWidget {
  final int currentPage;
  final int totalPages;

  const GoToPageDialog({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  State<GoToPageDialog> createState() => _GoToPageDialogState();
}

class _GoToPageDialogState extends State<GoToPageDialog> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentPage}');
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.find_in_page, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('انتقل إلى صفحة'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '1 - ${widget.totalPages}',
              errorText: _errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => _handleSubmit(),
          ),
          const SizedBox(height: 8),
          Text(
            'الصفحة الحالية: ${widget.currentPage}',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _handleSubmit,
          child: const Text('انتقل'),
        ),
      ],
    );
  }

  void _handleSubmit() {
    final page = int.tryParse(_controller.text);
    if (page == null || page < 1 || page > widget.totalPages) {
      setState(() {
        _errorText = 'أدخل رقم صفحة من 1 إلى ${widget.totalPages}';
      });
      return;
    }
    Navigator.pop(context, page);
  }
}
