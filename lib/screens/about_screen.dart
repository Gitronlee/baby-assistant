import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('小宝助手', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('版本: 1.0.0'),
                  SizedBox(height: 8),
                  Text('开发者：OpenAI 模型协助'),
                  SizedBox(height: 8),
                  Text('一个帮助妈妈记录婴儿睡眠、喂养和成长的简易助手应用。'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}