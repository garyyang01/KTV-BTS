import 'package:flutter/material.dart';
import 'services/email_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EmailService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final EmailService _emailService = EmailService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _status = '請填寫完整資訊後申請門票';
  bool _isLoading = false;
  bool _isAdult = true;
  String _session = '上半場';
  DateTime? _visitDate;
  TimeOfDay? _visitTime;

  void _sendTicketRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_visitDate == null || _visitTime == null) {
      setState(() {
        _status = '請選擇參觀日期和時間';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '正在寄信給老闆...';
    });

    final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
    final visitDateTime = DateTime(
      _visitDate!.year,
      _visitDate!.month,
      _visitDate!.day,
      _visitTime!.hour,
      _visitTime!.minute,
    );

    final success = await _emailService.sendTicketRequestToBoss(
      userName: _nameController.text.trim(),
      isAdult: _isAdult,
      destination: _session,
      orderId: orderId,
      visitDateTime: visitDateTime,
    );

    setState(() {
      _isLoading = false;
      if (success) {
        _status = '郵件已發送！正在等待老闆回覆...\n訂單編號: $orderId';
      } else {
        _status = '發送失敗，請檢查網路連線';
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _visitDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _visitTime = picked;
      });
    }
  }

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

              // 上下半場選擇
              const Text('場次選擇', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _session,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                items: const [
                  DropdownMenuItem(value: '上半場', child: Text('上半場')),
                  DropdownMenuItem(value: '下半場', child: Text('下半場')),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _session = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),

              // 參觀日期選擇
              const Text('參觀日期', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 10),
                      Text(
                        _visitDate == null
                            ? '選擇參觀日期'
                            : '${_visitDate!.year}/${_visitDate!.month}/${_visitDate!.day}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _visitDate == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 參觀時間選擇
              const Text('參觀時間', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 10),
                      Text(
                        _visitTime == null
                            ? '選擇參觀時間'
                            : '${_visitTime!.hour.toString().padLeft(2, '0')}:${_visitTime!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _visitTime == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 狀態顯示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),

              // 申請按鈕
              ElevatedButton(
                onPressed: _isLoading ? null : _sendTicketRequest,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('申請門票', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
