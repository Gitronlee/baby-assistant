import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final String appName = 'Baby Assistant';
    final String version = '1.0.0';
    final String developer = '开发者：OpenAI 模型协助';
    final String description = '一个帮助妈妈记录婴儿睡眠、喂养和成长的简易助手应用。';
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appName, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Version: $version'),
                  const SizedBox(height: 8),
                  Text(developer),
                  const SizedBox(height: 8),
                  Text(description),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}