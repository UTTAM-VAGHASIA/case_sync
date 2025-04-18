import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PriorityDialog extends StatefulWidget {
  final Function(int?, String?) onPrioritySelected;
  final String? initialPriority;
  final String? initialRemark;

  const PriorityDialog({
    super.key, 
    required this.onPrioritySelected,
    this.initialPriority,
    this.initialRemark,
  });

  @override
  State<PriorityDialog> createState() => _PriorityDialogState();
}

class _PriorityDialogState extends State<PriorityDialog> {
  late TextEditingController priorityController;
  late TextEditingController remarkController;
  bool isEditing = false;
  
  @override
  void initState() {
    super.initState();
    priorityController = TextEditingController(text: widget.initialPriority);
    remarkController = TextEditingController(text: widget.initialRemark);
    isEditing = widget.initialPriority != null;
  }
  
  @override
  void dispose() {
    priorityController.dispose();
    remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Color(0xFFF3F3F3),
      elevation: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? "Edit Priority" : "Set Priority",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    if (isEditing)
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Remove Priority"),
                              content: Text("Are you sure you want to remove the priority for this case?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close confirmation dialog
                                    widget.onPrioritySelected(null, null);
                                    Navigator.pop(context); // Close priority dialog
                                  },
                                  child: Text(
                                    "Remove",
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade300,
                          size: 24,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  "Set case priority and add relevant remarks",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // Form content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Priority Number",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: priorityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Enter priority number",
                      hintStyle: TextStyle(color: Colors.black38),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(
                        Icons.flag_outlined,
                        color: Colors.black54,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.black38, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.black, width: 1.5),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  Text(
                    "Remark",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: remarkController,
                    style: TextStyle(fontSize: 16),
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Add remark (if any)",
                      hintStyle: TextStyle(color: Colors.black38),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8,),
                        child: Icon(
                          Icons.comment_outlined,
                          color: Colors.black54,
                          size: 20,
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.black38, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.black, width: 1.5),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.black, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            int? priority = int.tryParse(priorityController.text);
                            String? remark = remarkController.text.trim();
                            if (remark.isEmpty) remark = null;
                            
                            widget.onPrioritySelected(priority, remark);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Save",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}