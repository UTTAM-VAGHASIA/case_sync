import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSearchPressed;
  final VoidCallback onFilterPressed;
  final bool isSearching;

  const ListAppBar({
    super.key,
    required this.onSearchPressed,
    required this.onFilterPressed,
    this.isSearching = false, // Default is false (not searching)
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
      elevation: 0,
      leadingWidth: 56 + 30,
      leading: IconButton(
        icon: SvgPicture.asset(
          'assets/icons/back_arrow.svg',
          width: 32,
          height: 32,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      actions: [
        // Filter Icon
        IconButton(
          icon: const Icon(Icons.filter_list_alt, size: 32, color: Colors.black),
          onPressed: onFilterPressed,
        ),

        // Search Icon (changes to cross when searching)
        IconButton(
          padding: EdgeInsets.only(left: 10.0 ,right: 20.0),
          icon: Icon(
            isSearching ? Icons.close : Icons.search_rounded,
            size: 32,// Toggle between search and close icons
            color: Colors.black,
          ),
          onPressed: onSearchPressed, // Trigger the search bar toggle
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}