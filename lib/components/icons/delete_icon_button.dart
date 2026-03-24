import 'package:flutter/material.dart';

class DeleteIconButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DeleteIconButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(),
      child: IconButton(
        icon: const Icon(Icons.delete, size: 24),
        color: const Color.fromARGB(255, 238, 16, 0),
        onPressed: onPressed,
      ),
    );
  }
}
