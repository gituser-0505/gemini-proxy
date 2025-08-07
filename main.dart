import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'screens/home_screen.dart';
import 'screens/webview_screen.dart';
import 'screens/history_screen.dart';
import 'models/history_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Настраиваем логирование
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  final logger = Logger('WebRusApp');
  
  // Загружаем переменные окружения
  try {
    await dotenv.load(fileName: ".env");
    logger.info('Переменные окружения загружены успешно');
  } catch (e) {
    logger.warning('Ошибка загрузки .env файла: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true; // По умолчанию темная тема для браузера

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebRus Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Metrika',
      ),
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF6366F1),
          surface: Color(0xFF1A1A2E),
        ),
        useMaterial3: true,
        fontFamily: 'Metrika',
        scaffoldBackgroundColor: const Color(0xFF0F0F23),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A2E),
          selectedItemColor: Color(0xFF6366F1),
          unselectedItemColor: Colors.grey,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: BrowserScreen(onToggleTheme: _toggleTheme),
    );
  }
}

class BrowserScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const BrowserScreen({super.key, required this.onToggleTheme});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final Logger _logger = Logger('BrowserScreen');
  int _currentIndex = 0;
  final TextEditingController _urlController = TextEditingController();
  
  // Добавляем список для хранения истории
  final List<HistoryItem> _historyList = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _loadUrl() {
    String url = _urlController.text.trim();
    if (url.isEmpty) return;
    
    try {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        // Проверяем, является ли это поисковым запросом
        if (url.contains(' ') || !url.contains('.')) {
          url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
        } else {
          url = 'https://$url';
        }
      }
      // Открываем URL в WebViewScreen
      _openWebView(url);
    } catch (e) {
      _logger.warning('Ошибка при загрузке URL: $e');
      // Показываем ошибку пользователю
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $url')),
      );
    }
  }

  void _addToHistory(String title, String url, String faviconUrl) {
    // Удаляем дубликаты, чтобы не было повторов в истории
    _historyList.removeWhere((item) => item.url == url);
    // Добавляем новую запись в начало списка с текущим временем
    _historyList.insert(0, HistoryItem(
      title: title, 
      url: url, 
      faviconUrl: faviconUrl,
      accessTime: DateTime.now(),
    ));
    
    // Логируем добавление в историю
    _logger.info('Добавлено в историю: $title ($url) в ${DateTime.now()}');
  }

  void _openWebView(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewScreen(
          url: url,
          onClose: () => Navigator.of(context).pop(),
          onHistoryAdd: _addToHistory,
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0: // Home
        return HomeScreen(onResult: _openWebView);
      case 1: // Search
        return WebViewScreen(
          url: 'https://www.google.com',
          onClose: () => setState(() => _currentIndex = 0),
          onHistoryAdd: _addToHistory,
        );
      case 2: // History
        return HistoryScreen(
          items: _historyList,
          onItemTap: (item) {
            // При нажатии на элемент истории, обновляем время доступа
            _addToHistory(item.title, item.url, item.faviconUrl);
            _openWebView(item.url);
          },
        );
      case 3: // AI (центр)
        return _buildAIScreen();
      case 4: // Profile
        return _buildProfileScreen();
      default:
        return HomeScreen(onResult: _openWebView);
    }
  }

  Widget _buildAIScreen() {
    return Container(
      color: const Color(0xFF0F0F23),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'AI',
                style: TextStyle(
                  fontFamily: 'Metrika',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Искусственный интеллект',
              style: TextStyle(
                fontFamily: 'Metrika',
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return Container(
      color: const Color(0xFF0F0F23),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Профиль',
              style: TextStyle(
                fontFamily: 'Metrika',
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Записей в истории:',
                        style: TextStyle(
                          fontFamily: 'Metrika',
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${_historyList.length}',
                        style: const TextStyle(
                          fontFamily: 'Metrika',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _historyList.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('История очищена')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Очистить историю',
                      style: TextStyle(fontFamily: 'Metrika'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _urlController,
            style: const TextStyle(
              fontSize: 14, 
              color: Colors.white,
              fontFamily: 'Metrika',
            ),
            decoration: InputDecoration(
              hintText: 'Введите URL или поисковый запрос',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontFamily: 'Metrika',
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, size: 20, color: Colors.white),
                onPressed: _loadUrl,
              ),
            ),
            onSubmitted: (_) => _loadUrl(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6, color: Colors.white),
            onPressed: widget.onToggleTheme,
            tooltip: 'Переключить тему',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Меню настроек
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E), // Темный фон как на изображении
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'WEBRUS', 0),
                _buildNavItem(Icons.search, '', 1),
                _buildNavItem(Icons.history, '', 2),
                _buildNavItem(Icons.psychology, '', 3), // AI иконка
                _buildNavItem(Icons.person, '', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6366F1) // Фиолетовый фон для выбранного элемента
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? Colors.white // Белый цвет для иконки в выбранном элементе
                  : Colors.grey[400], // Серый цвет для невыбранных элементов
              size: 24,
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Metrika',
                color: isSelected
                    ? const Color(0xFF6366F1) // Фиолетовый цвет для текста
                    : Colors.transparent, // Прозрачный для невыбранных элементов
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}