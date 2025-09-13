import 'package:flutter/material.dart';
import 'services/email_service.dart';
import 'config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EmailService().initialize();
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
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final EmailService _emailService = EmailService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
class _LandingPageState extends State<LandingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _ageGroup = 'Adult';
  String _selectedTime = 'Morning';
  bool _isAdult = true;

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
  final List<String> _timeSlots = [
    'Morning', 'Afternoon'
  ];

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(),
            _buildValueProposition(),
            _buildFeaturesAndProof(),
            _buildTrustBuilders(),
            _buildEngagement(),
            _buildClosingSection(),
            _buildFooter(),
          ],
        ),
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
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Visit Neuschwanstein Castle – Your Fairytale Awaits',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Skip the lines and secure your spot at Germany\'s most magical castle.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.1),
              ),
              child: const Center(
                child: Icon(
                  Icons.castle,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildBookingForm(),
            const SizedBox(height: 20),
            _buildTrustSignals(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Adult'),
                    value: true,
                    groupValue: _isAdult,
                    onChanged: (value) {
                      setState(() {
                        _isAdult = value!;
                        _ageGroup = 'Adult';
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Under 18'),
                    value: false,
                    groupValue: _isAdult,
                    onChanged: (value) {
                      setState(() {
                        _isAdult = value!;
                        _ageGroup = 'Under 18';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTime,
              decoration: const InputDecoration(
                labelText: 'Preferred Time',
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _reserveTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Reserve My Ticket',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _buyNowFillLater,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Buy Now, Fill Details Later',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustSignals() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: List.generate(5, (index) {
            return const Icon(
              Icons.star,
              color: Colors.amber,
              size: 20,
            );
          }),
        ),
        const SizedBox(width: 16),
        const Text(
          'Official Ticket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        const Icon(
          Icons.security,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 4),
        const Text(
          'Secure Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildValueProposition() {
    return Container(
      padding: const EdgeInsets.all(40),
      color: Colors.grey[50],
      child: Column(
        children: [
          const Text(
            'Why Choose Us?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Long queues and sold-out tickets ruining your castle dreams?',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'We guarantee your entry with official partner tickets and flexible time slots.',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBenefit(Icons.check_circle, 'Guaranteed Entry'),
              _buildBenefit(Icons.schedule, 'Save Time'),
              _buildBenefit(Icons.camera_alt, 'Great Photos'),
              _buildBenefit(Icons.schedule_outlined, 'Flexible Slot'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF059669),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesAndProof() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Text(
            'What You Get',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeature(Icons.home, 'Interior Access'),
              _buildFeature(Icons.landscape, 'Best Viewpoints'),
              _buildFeature(Icons.event_available, 'Exact Time Slot'),
            ],
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 24,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const Text(
                  '"Amazing experience! No waiting in line and the castle was breathtaking. Highly recommended!"',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '- Sarah M., Verified Customer',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Column(
      children: [
        Icon(
          icon,
          size: 48,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBuilders() {
    return Container(
      padding: const EdgeInsets.all(40),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTrustItem(Icons.security, 'Secure Checkout'),
          _buildTrustItem(Icons.people, '200+ Booked This Season'),
          _buildTrustItem(Icons.verified, 'Official Tourism Partner'),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: const Color(0xFF059669),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEngagement() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          _buildFAQItem('What\'s included in the ticket?', 'Full interior access, guided tour, and exclusive viewpoints.'),
          _buildFAQItem('Can I change my time slot?', 'Yes, you can modify your booking up to 24 hours before your visit.'),
          _buildFAQItem('Is this suitable for children?', 'Absolutely! The castle tour is family-friendly and engaging for all ages.'),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _saveToWishlist,
            icon: const Icon(Icons.bookmark_add),
            label: const Text('Save to Wishlist'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClosingSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      color: const Color(0xFF1E3A8A),
      child: Column(
        children: [
          const Text(
            'Don\'t miss your chance to see the world\'s most famous fairytale castle—book in seconds.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _saveToWishlist,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Save to Wishlist'),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text('Chat', style: TextStyle(color: Colors.white)),
              ),
              const Text(' | ', style: TextStyle(color: Colors.white)),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.email, color: Colors.white),
                label: const Text('Email', style: TextStyle(color: Colors.white)),
              ),
              const Text(' | ', style: TextStyle(color: Colors.white)),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.help, color: Colors.white),
                label: const Text('Help Center', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(40),
      color: const Color(0xFF1F2937),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('About', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Help', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Other Destinations', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('Terms', style: TextStyle(color: Colors.white70)),
              ),
              const Text(' | ', style: TextStyle(color: Colors.white70)),
              TextButton(
                onPressed: () {},
                child: const Text('Privacy', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.facebook, color: Colors.white70),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.facebook, color: Colors.white70),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.facebook, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _reserveTicket() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket reserved for ${_nameController.text} at $_selectedTime'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  void _buyNowFillLater() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Proceeding to payment...'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _saveToWishlist() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to wishlist!'),
        backgroundColor: Color(0xFF6B7280),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
