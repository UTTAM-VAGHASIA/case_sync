import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'ios_alert_dialog.dart';

class SlideableCard extends StatelessWidget {
  final Widget child;
  final String name;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReassign;

  final bool canReassign;

  const SlideableCard({
    super.key,
    required this.child,
    required this.name,
    this.onEdit,
    this.onDelete,
    this.onReassign,
    this.canReassign = false,
  });

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    if (onDelete == null) return;

    await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => IOSAlertDialog(
        title: "Delete Item",
        message: "Are you sure you want to delete $name's data from the list?",
        cancelButtonText: "Cancel",
        confirmButtonText: "Delete",
        onConfirm: onDelete!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Theme colors for better consistency (optional, but recommended)
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color deleteColor = colorScheme.error; // Standard error color
    // Use less intense shades for non-destructive actions or specific brand colors
    final Color editColor = Colors.blue; // Example: Muted blue-grey
    final Color reassignColor = Colors.teal; // Example: Muted teal

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Slidable(
        key: UniqueKey(),

        // --- Start Action Pane (Edit) ---
        startActionPane: ActionPane(
          // Use BehindMotion for a cleaner look where actions slide under
          motion: const BehindMotion(),
          // Reduce the extent ratio - 20% width is often enough for one icon
          extentRatio: 0.20,
          children: [
            SlidableAction(
              onPressed: (context) => onEdit?.call(),
              backgroundColor: editColor,
              // Use a defined color
              foregroundColor: Colors.white,
              // Keep icons white for contrast
              icon: Icons.edit,
              // label: 'Edit', // REMOVED Label for cleaner look
              borderRadius: BorderRadius.zero,
              // Let the pane handle clipping
              padding: EdgeInsets.zero, // Reduce padding if needed
            ),
          ],
        ),

        // --- End Action Pane (Reassign, Delete) ---
        endActionPane: ActionPane(
          motion: const BehindMotion(), // Consistent motion
          // Adjust ratio for two icons - 40% should be sufficient
          extentRatio: (canReassign) ? 0.40 : 0.20,
          children: [
            // Reassign Action
            if (canReassign)
              SlidableAction(
                onPressed: (context) => onReassign?.call(),
                backgroundColor: reassignColor,
                // Use a defined color
                foregroundColor: Colors.white,
                icon: Icons.assignment_ind,
                // Or Icons.person_search, Icons.sync_alt
                // label: 'Reassign', // REMOVED Label
                borderRadius: BorderRadius.zero,
                padding: EdgeInsets.zero,
              ),

            // Delete Action
            SlidableAction(
              onPressed: _showDeleteConfirmation,
              backgroundColor: deleteColor,
              // Use theme error color
              foregroundColor: Colors.white,
              icon: CupertinoIcons.trash,
              // Or Icons.delete_outline
              // label: 'Delete', // REMOVED Label
              borderRadius: BorderRadius.zero,
              padding: EdgeInsets.zero,
            ),
          ],
        ),

        // Your main card content
        child: child,
      ),
    );
  }
}
