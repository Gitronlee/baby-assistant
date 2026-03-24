# 萌宝助手 (Baby Assistant)

一款专为新手爸妈设计的 Flutter 育儿辅助应用，帮助您轻松记录和管理宝宝的日常护理。

## 功能特性

- **助眠白噪声** - 内置多种白噪声音效（吹风机、雨声、海浪、白噪音），支持自定义音频，帮助宝宝安稳入睡
- **喂奶计时器** - 智能倒计时提醒，可自定义喂奶间隔，支持时间设置和重新计时
- **成长轨迹** - 记录宝宝体重等成长数据，可视化展示成长曲线
- **本地数据持久化** - 使用 SharedPreferences 保存设置和数据

## 技术栈

- Flutter 3.3+
- Material Design 3
- 中文本地化 (zh_CN)

## 依赖包

- `audioplayers` - 音频播放
- `shared_preferences` - 本地存储
- `fl_chart` - 图表展示
- `provider` - 状态管理
- `file_picker` - 文件选择
- `url_launcher` - 链接跳转

## 快速开始

```bash
# 克隆项目
git clone <repository-url>

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

## 项目结构

```
lib/
├── main.dart              # 应用入口
└── screens/
    ├── weight_screen.dart  # 成长轨迹
    ├── about_screen.dart   # 关于页面
    └── ...
```

## License

Private project - not published to pub.dev
