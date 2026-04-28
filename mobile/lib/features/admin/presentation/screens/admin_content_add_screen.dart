/// Admin add-content screen — form to create a new dhikr, dua, or recitation.
/// Validates all required fields before allowing submission.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_provider.dart';

class AdminContentAddScreen extends ConsumerStatefulWidget {
  const AdminContentAddScreen({super.key});

  @override
  ConsumerState<AdminContentAddScreen> createState() =>
      _AdminContentAddScreenState();
}

class _AdminContentAddScreenState
    extends ConsumerState<AdminContentAddScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _arabicCtrl = TextEditingController();
  final _transliterationCtrl = TextEditingController();
  final _translationCtrl = TextEditingController();
  final _audioUrlCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  String _category = 'dhikr';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _arabicCtrl.dispose();
    _transliterationCtrl.dispose();
    _translationCtrl.dispose();
    _audioUrlCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Add Content', style: AppTextStyles.headingMedium),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionLabel('Category'),
            const SizedBox(height: 8),
            _CategorySelector(
              value: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Title'),
            const SizedBox(height: 8),
            _Field(
              controller: _titleCtrl,
              hint: 'e.g. SubhanAllah',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required.' : null,
            ),
            const SizedBox(height: 16),
            _SectionLabel('Arabic Text'),
            const SizedBox(height: 8),
            _Field(
              controller: _arabicCtrl,
              hint: 'سُبْحَانَ اللَّهِ',
              textDirection: TextDirection.rtl,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Arabic text is required.' : null,
            ),
            const SizedBox(height: 16),
            _SectionLabel('Transliteration'),
            const SizedBox(height: 8),
            _Field(
              controller: _transliterationCtrl,
              hint: 'SubhanAllah',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Transliteration is required.'
                  : null,
            ),
            const SizedBox(height: 16),
            _SectionLabel('Translation'),
            const SizedBox(height: 8),
            _Field(
              controller: _translationCtrl,
              hint: 'Glory be to Allah',
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Translation is required.'
                  : null,
            ),
            const SizedBox(height: 16),
            _SectionLabel('Tags (comma-separated)'),
            const SizedBox(height: 8),
            _Field(
              controller: _tagsCtrl,
              hint: 'morning, general',
              validator: (v) {
                final tags = _parseTags(v ?? '');
                if (tags.isEmpty) return 'At least one tag is required.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _SectionLabel('Audio URL (optional)'),
            const SizedBox(height: 8),
            _Field(
              controller: _audioUrlCtrl,
              hint: 'https://supabase.co/storage/...',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final uri = Uri.tryParse(v.trim());
                if (uri == null || !uri.isAbsolute) {
                  return 'Enter a valid URL or leave blank.';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            _SubmitButton(
              isLoading: _isSubmitting,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final tags = _parseTags(_tagsCtrl.text);
    final audioUrl = _audioUrlCtrl.text.trim().isNotEmpty
        ? _audioUrlCtrl.text.trim()
        : null;

    final err = await ref.read(adminContentProvider.notifier).addContent(
          title: _titleCtrl.text.trim(),
          arabicText: _arabicCtrl.text.trim(),
          transliteration: _transliterationCtrl.text.trim(),
          translation: _translationCtrl.text.trim(),
          category: _category,
          tags: tags,
          audioUrl: audioUrl,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content created successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }
}

// ── Category selector ──────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      ('dhikr', 'Dhikr', Icons.auto_awesome_rounded, AppColors.brandTeal),
      ('dua', 'Dua', Icons.volunteer_activism_rounded, AppColors.brandGold),
      ('recitation', 'Recitation', Icons.menu_book_rounded,
          const Color(0xFF8E44AD)),
    ];

    return Row(
      children: options
          .map((o) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onChanged(o.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: value == o.$1
                            ? o.$4.withValues(alpha: 0.12)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: value == o.$1
                              ? o.$4
                              : AppColors.border,
                          width: value == o.$1 ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(o.$3,
                              color: value == o.$1
                                  ? o.$4
                                  : AppColors.textMuted,
                              size: 22),
                          const SizedBox(height: 4),
                          Text(
                            o.$2,
                            style: AppTextStyles.caption.copyWith(
                              color: value == o.$1 ? o.$4 : AppColors.textMuted,
                              fontWeight: value == o.$1
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ── Shared form widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTextStyles.headingSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ));
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.textDirection,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextDirection? textDirection;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textDirection: textDirection,
      style: AppTextStyles.body,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.brandTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isLoading ? AppColors.brandTealDark : AppColors.brandTeal,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandTeal.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text('Create Content',
                  style: AppTextStyles.button),
        ),
      ),
    );
  }
}
