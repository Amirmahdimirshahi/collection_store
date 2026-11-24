import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const CollectionStore());
}

class CollectionStore extends StatelessWidget {
  const CollectionStore({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Collection Store',

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF245B45)),
      ),

      home: const HomePage(userId: 0, userName: 'مهمان', phoneNumber: ''),
    );
  }
}
