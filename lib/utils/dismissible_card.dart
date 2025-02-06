import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DismissibleCard extends StatelessWidget {
  final Widget child;
  final String name;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DismissibleCard({
    super.key,
    required this.child,
    this.onEdit,
    this.onDelete,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Dismissible(
        key: UniqueKey(),
        background: Container(
          decoration: BoxDecoration(
            color: Colors.indigoAccent,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: const Icon(Icons.edit, color: Colors.white),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: const Icon(CupertinoIcons.trash, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd && onEdit != null) {
            onEdit!();
            return false;
          } else if (direction == DismissDirection.endToStart &&
              onDelete != null) {
            return false;
          }
          return false;
        },
        child: child,
      ),
    );
  }
}
