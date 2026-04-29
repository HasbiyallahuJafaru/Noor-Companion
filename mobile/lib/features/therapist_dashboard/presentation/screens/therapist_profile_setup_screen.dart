/// Profile setup / edit screen for therapists.
/// Pre-fills from the existing profile when editing; blank for first-time setup.
/// Maps to POST /api/v1/therapists/profile.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/therapist_dashboard_provider.dart';
import '../../domain/therapist_dashboard_models.dart';

class TherapistProfileSetupScreen extends ConsumerStatefulWidget {
  const TherapistProfileSetupScreen({super.key, this.existing});

  /// Pre-fill from an existing profile. Null = first-time setup.
  final TherapistOwnProfile? existing;

  @override
  ConsumerState<TherapistProfileSetupScreen> createState() =>
      _TherapistProfileSetupScreenState();
}

class _TherapistProfileSetupScreenState
    extends ConsumerState<TherapistProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bioCtrl;
  late final TextEditingController _specialisationsCtrl;
  late final TextEditingController _qualificationsCtrl;
  late final TextEditingController _languagesCtrl;
  late final TextEditingController _yearsCtrl;
  late final TextEditingController _rateCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _bioCtrl = TextEditingController(text: e?.bio ?? '');
    _specialisationsCtrl = TextEditingController(
      text: e?.specialisations.join(', ') ?? '',
    );
    _qualificationsCtrl = TextEditingController(
      text: e?.qualifications.join(', ') ?? '',
    );
    _languagesCtrl = TextEditingController(
      text: e?.languagesSpoken.join(', ') ?? '',
    );
    _yearsCtrl = TextEditingController(
      text: e != null && e.yearsExperience > 0 ? '${e.yearsExperience}' : '',
    );
    _rateCtrl = TextEditingController(
      text: e != null && e.sessionRateNgn > 0 ? '${e.sessionRateNgn}' : '',
    );
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _specialisationsCtrl.dispose();
    _qualificationsCtrl.dispose();
    _languagesCtrl.dispose();
    _yearsCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  /// Splits a comma-separated string into a trimmed, non-empty list.
  List<String> _parseList(String raw) =>
      raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final err = await ref.read(therapistProfileProvider.notifier).updateProfile(
          bio: _bioCtrl.text.trim(),
          specialisations: _parseList(_specialisationsCtrl.text),
          qualifications: _parseList(_qualificationsCtrl.text),
          languagesSpoken: _parseList(_languagesCtrl.text),
          yearsExperience: int.tryParse(_yearsCtrl.text.trim()) ?? 0,
          sessionRateNgn: int.tryParse(_rateCtrl.text.trim()) ?? 0,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Profile' : 'Set Up Your Profile',
          style: AppTextStyles.headingMedium,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _SectionLabel('About You'),
            _Field(
              controller: _bioCtrl,
              label: 'Bio',
              hint: 'Tell clients about your approach and experience…',
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Bio is required.' : null,
            ),
            const SizedBox(height: 20),
            _SectionLabel('Areas of Practice'),
            _Field(
              controller: _specialisationsCtrl,
              label: 'Specialisations',
              hint: 'anxiety, grief, spiritual wellness',
              hint2: 'Comma-separated',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'At least one specialisation.' : null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _qualificationsCtrl,
              label: 'Qualifications',
              hint: 'MSc Psychology, BACP Accredited',
              hint2: 'Comma-separated',
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _languagesCtrl,
              label: 'Languages Spoken',
              hint: 'English, Arabic',
              hint2: 'Comma-separated',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'At least one language.' : null,
            ),
            const SizedBox(height: 20),
            _SectionLabel('Session Details'),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _yearsCtrl,
                    label: 'Years Experience',
                    hint: '5',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Enter a valid number.';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    controller: _rateCtrl,
                    label: 'Rate (₦)',
                    hint: '15000',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter a valid rate.';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _SaveButton(isSaving: _isSaving, onTap: _save),
          ],
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: AppColors.brandTeal,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Field ──────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.hint2,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? hint2;
  final int maxLines;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            helperText: hint2,
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
            labelStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Save button ────────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onTap});
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSaving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: isSaving
              ? AppColors.brandTeal.withValues(alpha: 0.5)
              : AppColors.brandTeal,
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
          child: isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Save Profile',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
