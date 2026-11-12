import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/operation_status_provider.dart';
import '../theme/app_colors.dart';

class OperationStatusBanner extends StatelessWidget {
  const OperationStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Consumer<OperationStatusProvider>(
      builder: (context, operations, _) {
        final notice = operations.notice;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: notice == null
              ? const SizedBox(
                  key: ValueKey('empty-operation-status'),
                  height: 0,
                )
              : Container(
                  key: ValueKey('${notice.phase}-${notice.title}'),
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _backgroundColor(notice.phase, palette),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      if (notice.phase == OperationPhase.working)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.primary,
                          ),
                        )
                      else
                        Icon(
                          _icon(notice.phase),
                          size: 19,
                          color: _foregroundColor(notice.phase, palette),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notice.title,
                              style: TextStyle(
                                color: palette.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (notice.detail != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                notice.detail!,
                                style: TextStyle(
                                  color: palette.secondaryText,
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Meldung schließen',
                        onPressed: operations.dismiss,
                        icon: Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: palette.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Color _backgroundColor(OperationPhase phase, AppPalette palette) {
    return switch (phase) {
      OperationPhase.working => palette.lavenderSurface,
      OperationPhase.success => palette.lavenderSurface,
      OperationPhase.error => palette.roseSurface,
      OperationPhase.info => palette.surface,
    };
  }

  Color _foregroundColor(OperationPhase phase, AppPalette palette) {
    return phase == OperationPhase.error ? palette.error : palette.primary;
  }

  IconData _icon(OperationPhase phase) => switch (phase) {
    OperationPhase.working => Icons.hourglass_top_rounded,
    OperationPhase.success => Icons.check_circle_outline_rounded,
    OperationPhase.error => Icons.error_outline_rounded,
    OperationPhase.info => Icons.info_outline_rounded,
  };
}
