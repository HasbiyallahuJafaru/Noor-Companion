/// Admin broadcast screen — compose and send a push notification to a role.
/// Title + body fields, role selector, send button, success/error feedback.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_provider.dart';

class AdminBroadcastScreen extends ConsumerStatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  ConsumerState<AdminBroadcastScreen> createState() =>
      _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends ConsumerState<AdminBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _targetRole = 'user';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final broadcastState = ref.watch(broadcastProvider);

    // Show success overlay when sent.
    if (broadcastState is BroadcastSuccess) {
      return _SuccessView(
        sent: broadcastState.sent,
        onReset: () {
          ref.read(broadcastProvider.notifier).reset();
          _titleCtrl.clear();
          _bodyCtrl.clear();
          setState(() => _targetRole = 'user');
        },
      );
    }

    final isSending = broadcastState is BroadcastSending;
    final errorMsg =
        broadcastState is BroadcastError ? broadcastState.message : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Broadcast Notification', style: AppTextStyles.headingMedium),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _InfoBanner(),
            const SizedBox(height: 24),
            _SectionLabel('Target Audience'),
            const SizedBox(height: 10),
            _RoleSelector(
              value: _targetRole,
              onChanged: isSending ? null : (v) => setState(() => _targetRole = v),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Notification Title'),
            const SizedBox(height: 8),
            _Field(
              controller: _titleCtrl,
              hint: 'e.g. New Content Available',
              enabled: !isSending,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required.' : null,
            ),
            const SizedBox(height: 16),
            _SectionLabel('Notification Body'),
            const SizedBox(height: 8),
            _Field(
              controller: _bodyCtrl,
              hint: 'e.g. New evening adhkar have been added…',
              maxLines: 4,
              enabled: !isSending,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Body is required.' : null,
            ),
            if (errorMsg != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: errorMsg),
            ],
            const SizedBox(height: 32),
            _SendButton(
              isSending: isSending,
              targetRole: _targetRole,
              onTap: _send,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Broadcast?'),
        content: Text(
          'This will push a notification to all ${_roleLabel(_targetRole)}. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8E44AD)),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(broadcastProvider.notifier).send(
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          targetRole: _targetRole,
        );
  }

  String _roleLabel(String role) => switch (role) {
        'therapist' => 'therapists',
        'admin' => 'admins',
        _ => 'users',
      };
}

// ── Role selector ──────────────────────────────────────────────────────────────

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String>? onChanged;

  static const _options = [
    ('user', 'Users', Icons.people_rounded, AppColors.brandTeal),
    ('therapist', 'Therapists', Icons.health_and_safety_rounded,
        AppColors.success),
    ('admin', 'Admins', Icons.admin_panel_settings_rounded,
        Color(0xFF8E44AD)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options
          .map((o) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: onChanged != null ? () => onChanged!(o.$1) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: value == o.$1
                            ? o.$4.withValues(alpha: 0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: value == o.$1 ? o.$4 : AppColors.border,
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

// ── Send button ────────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.isSending,
    required this.targetRole,
    required this.onTap,
  });

  final bool isSending;
  final String targetRole;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF8E44AD);

    return GestureDetector(
      onTap: isSending ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSending ? purple.withValues(alpha: 0.5) : purple,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: purple.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isSending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.campaign_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Send Broadcast',
                        style: AppTextStyles.button),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Info banner ────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF8E44AD).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF8E44AD).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF8E44AD), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Broadcasts are sent immediately to all devices for the '
              'selected role. Use sparingly — push fatigue reduces engagement.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: const Color(0xFF8E44AD)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error banner ───────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Success view ───────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.sent, required this.onReset});
  final int sent;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Broadcast Sent', style: AppTextStyles.headingMedium),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 44),
              ),
              const SizedBox(height: 24),
              Text('Broadcast delivered!',
                  style: AppTextStyles.headingLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Notification sent to $sent device${sent == 1 ? '' : 's'}.',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Send Another',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.headingSmall
          .copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.enabled = true,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool enabled;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      style: AppTextStyles.body,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
