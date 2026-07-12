import 'package:flutter/material.dart';

class BoardScreen extends StatelessWidget {
  final String boardId;

  const BoardScreen({super.key, required this.boardId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Board Canvas: $boardId')),
      body: Center(child: Text('Canvas for $boardId will go here.')),
    );
  }
}
