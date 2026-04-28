/// Admin therapist management screen.
/// Shows pending therapist applications with approve / reject actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_provider.dart';
import '../../domain/admin_models.dart';

class AdminTherapistsScreen extends ConsumerWidget {
  const AdminTherapistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminTherapistsProvider);
    final notifier = ref.read(adminTherapistsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Therapist Applications', style: AppTextStyles.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.load,
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandTeal))
          : state.error != null
              ? _ErrorView(error: state.error!, onRetry: notifier.load)
              : state.pending.isEmpty
                  ? const _EmptyView()
                  : _PendingList(
                      therapists: state.pending,
                      onApprove: (t) => _handleApprove(context, ref, t),
                      onReject: (t) => _showRejectSheet(context, ref, t),
                    ),
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    WidgetRef ref,
    PendingTherapist therapist,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Approve ${therapist.fullName}?'),
        content: const Text(
            'They will be added to the therapist directory and notified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.success),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final err = await ref
        .read(adminTherapistsProvider.notifier)
        .approve(therapist.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? '${therapist.fullName} approved.'),
          backgroundColor: err != null ? AppColors.error : AppColors.success,
        ),
      );
    }
  }

  Future<void> _showRejectSheet(
    BuildContext context,
    WidgetRef ref,
    PendingTherapist therapist,
  ) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _RejectSheet(
        therapist: therapist,
        controller: controller,
        onReject: (reason) async {
          Navigator.pop(sheetCtx);
          final err = await ref
              .read(adminTherapistsProvider.notifier)
              .reject(therapist.id, reason);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err ?? '${therapist.fullName} rejected.'),
                backgroundColor:
                    err != null ? AppColors.error : AppColors.textMuted,
              ),
            );
          }
        },
      ),
    );
    controller.dispose();
  }
}

// ── Pending list ───────────────────────────────────────────────────────────────

class _PendingList extends StatelessWidget {
  const _PendingList({
    required this.therapists,
    required this.onApprove,
    required this.onReject,
  });

  final List<PendingTherapist> therapists;
  final ValueChanged<PendingTherapist> onApprove;
  final ValueChanged<PendingTherapist> onReject;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: therapists.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _TherapistCard(
        therapist: therapists[i],
        onApprove: () => onApprove(therapists[i]),
        onReject: () => onReject(therapists[i]),
      ),
    );
  }
}

class _TherapistCard extends StatelessWidget {
  const _TherapistCard({
    required this.therapist,
    required this.onApprove,
    required this.onReject,
  });

  final PendingTherapist therapist;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandTeal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InitialsAvatar(name: therapist.fullName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(therapist.fullName,
                        style: AppTextStyles.headingSmall),
                    Text(
                      '${therapist.yearsExperience} yrs exp · ₦${_fmt(therapist.sessionRateNgn)}/session',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                _daysSince(therapist.createdAt),
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (therapist.bio.isNotEmpty) ...[
            Text(
              therapist.bio,
              style: AppTextStyles.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
          ],
          _TagRow(
            label: 'Specialisations',
            tags: therapist.specialisations,
            color: AppColors.brandTeal,
          ),
          const SizedBox(height: 6),
          _TagRow(
            label: 'Qualifications',
            tags: therapist.qualifications,
            color: AppColors.brandGold,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: 'Reject',
                  color: AppColors.error,
                  onTap: onReject,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionBtn(
                  label: 'Approve',
                  color: AppColors.success,
                  filled: true,
                  onTap: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  String _daysSince(DateTime dt) {
    final diff = DateTime.now().difference(dt).inDays;
    return diff == 0 ? 'Today' : '${diff}d ago';
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.label, required this.tags, required this.color});
  final String label;
  final List<String> tags;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted)),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: tags
                .map((t) => _MiniChip(label: t, color: color))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: filled ? Colors.white : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Reject sheet ───────────────────────────────────────────────────────────────

class _RejectSheet extends StatefulWidget {
  const _RejectSheet({
    required this.therapist,
    required this.controller,
    required this.onReject,
  });

  final PendingTherapist therapist;
  final TextEditingController controller;
  final ValueChanged<String> onReject;

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reject ${widget.therapist.fullName}',
              style: AppTextStyles.headingMedium),
          const SizedBox(height: 4),
          Text(
            'Provide a reason — they will be notified.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Reason for rejection…',
              filled: true,
              fillColor: AppColors.background,
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
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.controller.text.trim().length >= 5
                  ? () => widget.onReject(widget.controller.text.trim())
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                disabledBackgroundColor: AppColors.border,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reject Application',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Initials avatar ────────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ');
    final initials =
        parts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.success,
            )),
      ),
    );
  }
}

// ── Empty / Error ──────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 64, color: AppColors.success.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text('No pending applications',
              style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text('All therapist applications have been reviewed.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.brandTeal),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
