import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('萌宝助手', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('版本: 1.0.0'),
                  const SizedBox(height: 8),
                  const Text('开发者：熹熹爸'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _launchUrl('https://github.com/Gitronlee/baby-assistant'),
                    child: const Text(
                      'GitHub: github.com/Gitronlee/baby-assistant',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _launchUrl('mailto:ronlee@live.cn'),
                    child: const Text(
                      '邮箱: ronlee@live.cn',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('一个帮助父母记录宝宝睡眠、喂养和成长的温馨助手应用。'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}