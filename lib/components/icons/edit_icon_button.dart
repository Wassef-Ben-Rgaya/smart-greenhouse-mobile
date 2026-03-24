import 'package:flutter/material.dart';

class EditIconButton extends StatelessWidget {
  final VoidCallback onPressed;

  const EditIconButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.edit_square, size: 24),
      color: const Color.fromARGB(255, 53, 53, 53),
      onPressed: onPressed,
    );
  }
}
