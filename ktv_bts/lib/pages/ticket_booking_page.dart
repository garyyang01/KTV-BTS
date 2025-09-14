import 'package:flutter/material.dart';
import '../widgets/booking_form.dart';

/// 主要票務預訂頁面
/// 包含城堡資訊展示和票券預訂表單
class TicketBookingPage extends StatefulWidget {
  const TicketBookingPage({super.key});

  @override
  State<TicketBookingPage> createState() => _TicketBookingPageState();
}

class _TicketBookingPageState extends State<TicketBookingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuschwanstein Castle Tickets'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          // 鐵路搜尋測試按鈕
          IconButton(
            icon: const Icon(Icons.train),
            tooltip: '鐵路搜尋測試',
            onPressed: () {
              Navigator.pushNamed(context, '/rail-search-test');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            _buildHeroSection(),
            
            // Booking Form Section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book Your Tickets',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  BookingForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 建立 Hero Section
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Castle Image
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/neuschwanstein_castle.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.castle,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Neuschwanstein Castle',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Image not found',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Main Title
            const Text(
              'Visit Neuschwanstein Castle – Your Fairytale Awaits',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            const Text(
              'Skip the lines and secure your spot at Germany\'s most magical castle.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}