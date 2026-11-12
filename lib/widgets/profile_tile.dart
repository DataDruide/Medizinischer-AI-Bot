import 'package:flutter/material.dart';

import '../services/profile_storage_service.dart';
import '../theme/app_colors.dart';

class ProfileTile extends StatelessWidget {
  const ProfileTile({
    required this.profile,
    required this.enabled,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final LocalProfileSummary profile;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
          decoration: BoxDecoration(
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: palette.lavenderSurface,
                child: Icon(Icons.person_outline, color: palette.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  profile.name,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: enabled ? onDelete : null,
                tooltip: 'Profil löschen',
                icon: const Icon(Icons.delete_outline_rounded),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.mutedText),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
