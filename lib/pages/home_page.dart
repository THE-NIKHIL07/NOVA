import 'package:flutter/material.dart';
import 'package:nova/widgets/side_bar.dart';

class HomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Row(
        children: [
          SideBar(),
          Column(
            children: [

            ],
          )
        ],
      )
    );
  }
}