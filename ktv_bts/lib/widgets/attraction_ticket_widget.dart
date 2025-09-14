import 'package:flutter/material.dart';
import '../models/search_option.dart';
import '../widgets/booking_form.dart';

/// 景點門票組件 - 整合現有的景點門票申請表單
class AttractionTicketWidget extends StatefulWidget {
  final SearchOption? selectedAttraction;

  const AttractionTicketWidget({
    super.key,
    this.selectedAttraction,
  });

  @override
  State<AttractionTicketWidget> createState() => _AttractionTicketWidgetState();
}

class _AttractionTicketWidgetState extends State<AttractionTicketWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // 啟動動畫
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題區域
              _buildHeader(),
              
              const SizedBox(height: 20),
              
              // 景點資訊卡片
              if (widget.selectedAttraction != null) ...[
                _buildAttractionInfo(),
                const SizedBox(height: 20),
              ],
              
              // 票券申請表單
              _buildBookingSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// 建立標題區域
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.local_activity,
          color: Colors.orange.shade600,
          size: 24,
        ),
        const SizedBox(width: 8),
        const Text(
          'Attraction Ticket Booking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// 建立景點資訊卡片
  Widget _buildAttractionInfo() {
    final attraction = widget.selectedAttraction!;
    final metadata = attraction.metadata ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade50,
            Colors.orange.shade100.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 景點名稱和圖標
          Row(
            children: [
              Text(
                attraction.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attraction.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      attraction.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 景點詳細資訊
          _buildInfoGrid(metadata),
          
          const SizedBox(height: 12),
          
          // 票價資訊
          _buildPriceInfo(metadata),
        ],
      ),
    );
  }

  /// 建立資訊網格
  Widget _buildInfoGrid(Map<String, dynamic> metadata) {
    final List<Map<String, String>> infoItems = [];
    
    if (metadata['country'] != null) {
      infoItems.add({
        'icon': '🏳️',
        'label': 'Country',
        'value': metadata['country'].toString(),
      });
    }
    
    if (metadata['city'] != null) {
      infoItems.add({
        'icon': '🏙️',
        'label': 'City',
        'value': metadata['city'].toString(),
      });
    }
    
    if (metadata['openingHours'] != null) {
      infoItems.add({
        'icon': '🕒',
        'label': 'Hours',
        'value': metadata['openingHours'].toString(),
      });
    }

    if (infoItems.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: infoItems.map((item) => _buildInfoChip(
        item['icon']!,
        item['label']!,
        item['value']!,
      )).toList(),
    );
  }

  /// 建立資訊標籤
  Widget _buildInfoChip(String icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立票價資訊
  Widget _buildPriceInfo(Map<String, dynamic> metadata) {
    final ticketPrice = metadata['ticketPrice'] as Map<String, dynamic>?;
    
    if (ticketPrice == null) {
      return const SizedBox.shrink();
    }

    final adultPrice = ticketPrice['adult'] as int? ?? 0;
    final childPrice = ticketPrice['child'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.euro,
                size: 16,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                'Ticket Prices',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildPriceItem(
                  'Adult (18+)',
                  adultPrice,
                  Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPriceItem(
                  'Under 18',
                  childPrice,
                  Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 建立價格項目
  Widget _buildPriceItem(String label, int price, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            price == 0 ? 'Free' : '€$price',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立預訂區域
  Widget _buildBookingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 區段標題
        Row(
          children: [
            Icon(
              Icons.confirmation_number,
              color: Colors.orange.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Ticket Booking Form',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // 說明文字
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please fill in the booking details below. You can add multiple tickets for your group.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 整合現有的 BookingForm
        BookingForm(selectedAttraction: widget.selectedAttraction),
      ],
    );
  }
}
