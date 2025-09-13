import 'package:flutter/material.dart';
import 'services/email_service.dart';
import 'pages/payment_test_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 嘗試初始化 EmailService，如果失敗則繼續運行
  try {
    await EmailService().initialize();
  } catch (e) {
    print('EmailService initialization failed: $e');
    // 繼續運行應用程式，即使 EmailService 初始化失敗
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neuschwanstein Castle Tickets',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LandingPage(),
      routes: {
        '/payment-test': (context) => const PaymentTestPage(),
      },
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedTime = 'Morning';
  bool _isAdult = true;

  void _sendTicketRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ticket reserved for ${_nameController.text} at $_selectedTime'),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  final List<String> _timeSlots = [
    'Morning', 'Afternoon'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('新天鵝堡門票系統'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Center(
                child: Icon(
                  Icons.castle,
                  size: 80,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  '新天鵝堡門票申請',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),

              // 姓名輸入
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '姓名（必須與護照相同）',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入姓名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 成人/兒童選擇
              const Text('票種選擇', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('成人票'),
                      value: true,
                      groupValue: _isAdult,
                      onChanged: (bool? value) {
                        setState(() {
                          _isAdult = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('兒童票'),
                      value: false,
                      groupValue: _isAdult,
                      onChanged: (bool? value) {
                        setState(() {
                          _isAdult = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 時間選擇
              const Text('時間選擇', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedTime,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                items: _timeSlots.map((time) {
                  return DropdownMenuItem(
                    value: time,
                    child: Text(time),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTime = value!;
                  });
                },
              ),
              const SizedBox(height: 30),

              // 申請按鈕
              ElevatedButton(
                onPressed: _sendTicketRequest,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('申請門票', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/payment-test'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('🧪 開發者測試頁面', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}